<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Http\Resources\StoryApiResource;
use App\Models\VendorStory;
use App\Models\VendorStoryView;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Modules\Core\Entities\Item\Item;
use Modules\Core\Entities\Vendor\Vendor;
use Modules\Core\Transformers\Api\App\V1_0\Item\ItemApiResource;

class StoryApiController extends Controller
{
    /**
     * Get active 24h stories feed.
     */
    public function feed(Request $request)
    {
        try {
            $loginUserId = $request->header('login_user_id') 
                ?? $request->query('login_user_id') 
                ?? $request->input('login_user_id') 
                ?? $request->user()?->id;

            $now = Carbon::now();

            $activeStories = VendorStory::where('expires_at', '>', $now)
                ->with(['user', 'vendor.logo', 'item.cover', 'item.currency'])
                ->orderBy('created_at', 'asc')
                ->get();

            // Group by vendor or seller
            $myStories = [];
            $vendorsMap = [];

            foreach ($activeStories as $story) {
                $isMine = (!empty($loginUserId) && (string)$loginUserId !== 'nologinuser' && (string)$loginUserId === (string)$story->user_id);

                if ($isMine) {
                    $myStories[] = new StoryApiResource($story);
                }

                // Grouping key: vendor_id if exists and > 0, otherwise "user_" . user_id
                $hasVendor = !empty($story->vendor_id) && (int)$story->vendor_id > 0;
                $groupKey = $hasVendor ? 'vendor_' . $story->vendor_id : 'user_' . $story->user_id;

                if (!isset($vendorsMap[$groupKey])) {
                    $user = $story->user;
                    $vendor = $story->vendor;
                    $vendorName = $vendor?->name ?? $user?->name ?? 'Dressy Vendeur';

                    // Resolve seller avatar (vendor-logo or user cover/profile photo)
                    $avatarPath = '';
                    $avatarUrl = '';

                    if ($hasVendor && $vendor?->logo?->img_path) {
                        $avatarPath = $vendor->logo->img_path;
                    } elseif ($hasVendor) {
                        $vLogo = \Modules\Core\Entities\CoreImage::where('img_parent_id', $story->vendor_id)
                            ->where('img_type', 'vendor-logo')
                            ->value('img_path');
                        if (!empty($vLogo)) {
                            $avatarPath = $vLogo;
                        }
                    }

                    if (empty($avatarPath) && $user) {
                        if (!empty($user->user_cover_photo)) {
                            $avatarPath = $user->user_cover_photo;
                        } elseif (!empty($user->user_profile_photo)) {
                            $avatarPath = $user->user_profile_photo;
                        }
                    }

                    if (!empty($avatarPath)) {
                        if (str_starts_with($avatarPath, 'http://') || str_starts_with($avatarPath, 'https://')) {
                            $avatarUrl = $avatarPath;
                        } else {
                            $clean = ltrim($avatarPath, '/');
                            if (File::exists(public_path('storage/PSX_MPC/uploads/' . $clean))) {
                                $avatarUrl = asset('storage/PSX_MPC/uploads/' . $clean);
                            } elseif (File::exists(public_path('uploads/' . $clean))) {
                                $avatarUrl = asset('uploads/' . $clean);
                            } else {
                                $avatarUrl = asset('storage/PSX_MPC/uploads/' . $clean);
                            }
                        }
                    }

                    $vendorsMap[$groupKey] = [
                        'group_key' => $groupKey,
                        'vendor_id' => $hasVendor ? (string) $story->vendor_id : '',
                        'vendor_user_id' => (string) $story->user_id,
                        'vendor_name' => $vendorName,
                        'vendor_logo' => $avatarUrl,
                        'vendor_logo_path' => $avatarPath,
                        'avatar_path' => $avatarPath,
                        'avatar_url' => $avatarUrl,
                        'is_mine' => $isMine,
                        'has_unseen' => true,
                        'latest_story_at' => '',
                        'has_active_stories' => true,
                        'stories' => [],
                    ];
                }

                $vendorsMap[$groupKey]['stories'][] = new StoryApiResource($story);
                $storyCreatedAt = $story->created_at ? $story->created_at->format('Y-m-d H:i:s') : (string) $story->added_date;
                if (empty($vendorsMap[$groupKey]['latest_story_at']) || strcmp($storyCreatedAt, $vendorsMap[$groupKey]['latest_story_at']) > 0) {
                    $vendorsMap[$groupKey]['latest_story_at'] = $storyCreatedAt;
                }
            }

            // Order vendors so that latest stories appear first
            uasort($vendorsMap, function ($a, $b) {
                return strcmp($b['latest_story_at'] ?? '', $a['latest_story_at'] ?? '');
            });

            return response()->json([
                'status' => 'success',
                'data' => [
                    'my_stories' => $myStories,
                    'stories_by_vendor' => array_values($vendorsMap),
                    'total_active' => $activeStories->count(),
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('Stories feed error: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
            return response()->json([
                'status' => 'error',
                'message' => 'Erreur lors du chargement des stories: ' . $e->getMessage(),
                'data' => [
                    'my_stories' => [],
                    'stories_by_vendor' => [],
                    'total_active' => 0,
                ],
            ], 500);
        }
    }

    /**
     * Get active items belonging to the authenticated seller/vendor for story tagging.
     */
    public function myItems(Request $request)
    {
        try {
            $loginUserId = $request->header('login_user_id') 
                ?? $request->query('login_user_id') 
                ?? $request->input('login_user_id') 
                ?? $request->user()?->id;

            if (empty($loginUserId) || (string)$loginUserId === 'nologinuser') {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Authentification requise pour charger vos articles.',
                ], 401);
            }

            $vendorId = Vendor::where('owner_user_id', $loginUserId)->value('id');

            $items = Item::where('status', 1)
                ->where(function ($query) use ($loginUserId, $vendorId) {
                    $query->where('added_user_id', $loginUserId);
                    if (!empty($vendorId)) {
                        $query->orWhere('vendor_id', $vendorId);
                    }
                })
                ->with([
                    'cover' => function ($q) {
                        $q->where('img_type', 'item')->orderBy('ordering', 'asc');
                    },
                    'currency',
                    'category',
                ])
                ->latest('id')
                ->limit(60)
                ->get();

            return ItemApiResource::collection($items);
        } catch (\Throwable $e) {
            Log::error('Error fetching seller story items: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
            return response()->json([
                'status' => 'error',
                'message' => 'Erreur lors du chargement des articles: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Upload a new story slide (photo or video).
     */
    public function upload(Request $request)
    {
        try {
            $loginUserId = $request->header('login_user_id') 
                ?? $request->input('login_user_id') 
                ?? $request->query('login_user_id')
                ?? $request->user()?->id;

            if (empty($loginUserId) || (string)$loginUserId === 'nologinuser') {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Authentification requise pour publier une story.',
                ], 401);
            }

            // Support multiple multipart file field names: media_file, media, file, image
            $file = $request->file('media_file') 
                ?? $request->file('media') 
                ?? $request->file('file') 
                ?? $request->file('image');

            $mediaPath = '';
            $thumbnailPath = '';
            $mediaType = $request->input('media_type', 'image');

            if (!$file && !$request->filled('media_path')) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Veuillez sélectionner un fichier photo ou vidéo.',
                ], 422);
            }

            // Ensure destination directory exists in public/uploads/stories
            $uploadSubdir = 'uploads/stories/' . date('Y/m');
            $storiesDir = public_path($uploadSubdir);
            try {
                File::ensureDirectoryExists($storiesDir, 0755, true);
            } catch (\Throwable $dirEx) {
                $uploadSubdir = 'uploads/stories';
                $storiesDir = public_path($uploadSubdir);
                File::ensureDirectoryExists($storiesDir, 0755, true);
            }

            if ($file) {
                // Validate size (max 25MB)
                $maxBytes = 25 * 1024 * 1024;
                if ($file->getSize() > $maxBytes) {
                    return response()->json([
                        'status' => 'error',
                        'message' => 'Le fichier média ne doit pas dépasser 25 Mo.',
                    ], 422);
                }

                $extension = strtolower($file->getClientOriginalExtension() ?: 'jpg');
                $allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'gif', 'mp4', 'mov', 'avi', 'm4v', 'webm', '3gp'];
                if (!in_array($extension, $allowedExtensions)) {
                    return response()->json([
                        'status' => 'error',
                        'message' => 'Format de fichier non supporté (autorisés: JPG, PNG, WEBP, MP4, MOV).',
                    ], 422);
                }

                if (in_array($extension, ['mp4', 'mov', 'avi', 'm4v', 'webm', '3gp'])) {
                    $mediaType = 'video';
                } else {
                    $mediaType = 'image';
                }

                $fileName = 'story_' . $loginUserId . '_' . time() . '_' . uniqid() . '.' . $extension;
                $file->move($storiesDir, $fileName);
                $mediaPath = 'stories/' . date('Y/m') . '/' . $fileName;
            } elseif ($request->filled('media_path')) {
                $mediaPath = ltrim(preg_replace('#^/?uploads/#', '', $request->input('media_path')), '/');
            }

            // Thumbnail processing for videos
            $thumb = $request->file('thumbnail_file') 
                ?? $request->file('thumbnail') 
                ?? $request->file('thumb');

            if ($thumb) {
                $thumbExt = strtolower($thumb->getClientOriginalExtension() ?: 'jpg');
                $thumbName = 'thumb_' . $loginUserId . '_' . time() . '_' . uniqid() . '.' . $thumbExt;
                $thumb->move($storiesDir, $thumbName);
                $thumbnailPath = 'stories/' . date('Y/m') . '/' . $thumbName;
            } elseif ($mediaType === 'image') {
                $thumbnailPath = $mediaPath;
            }

            $duration = (int) $request->input('duration', ($mediaType === 'video' ? 15 : 5));
            $filterPreset = $request->input('filter_preset', 'original');

            // Detect vendor profile if passed or if user owns one
            $rawVendorId = $request->input('vendor_id');
            $vendor = null;
            if (!empty($rawVendorId) && (int)$rawVendorId > 0) {
                $vendor = Vendor::find($rawVendorId);
            }
            if (!$vendor) {
                $vendor = Vendor::where('owner_user_id', $loginUserId)->first();
            }

            // Assemble story data with Schema::hasColumn guards for DB resiliency
            $storyData = [
                'user_id' => $loginUserId,
                'media_type' => $mediaType,
                'media_path' => $mediaPath,
                'thumbnail_path' => $thumbnailPath,
                'caption' => $request->input('caption'),
                'duration' => $duration,
                'expires_at' => Carbon::now()->addHours(24),
                'added_date' => Carbon::now(),
                'added_user_id' => $loginUserId,
            ];

            if (Schema::hasColumn('psx_vendor_stories', 'vendor_id')) {
                $storyData['vendor_id'] = $vendor ? $vendor->id : 0;
            }

            if (Schema::hasColumn('psx_vendor_stories', 'item_id')) {
                $rawItemId = $request->input('item_id');
                $storyData['item_id'] = (!empty($rawItemId) && is_numeric($rawItemId)) ? (int)$rawItemId : null;
            }

            if (Schema::hasColumn('psx_vendor_stories', 'filter_preset')) {
                $storyData['filter_preset'] = $filterPreset;
            }

            if (Schema::hasColumn('psx_vendor_stories', 'views_count')) {
                $storyData['views_count'] = 0;
            }

            $story = VendorStory::create($storyData);

            // Safely eager load relations
            try {
                $story->load(['user', 'vendor.logo']);
                if (Schema::hasColumn('psx_vendor_stories', 'item_id') && !empty($story->item_id)) {
                    $story->load(['item.cover', 'item.currency']);
                }
            } catch (\Throwable $relEx) {
                Log::warning('Story relation eager loading warning: ' . $relEx->getMessage());
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Story publiée avec succès.',
                'data' => new StoryApiResource($story),
            ]);
        } catch (\Throwable $e) {
            Log::error('Story upload failed: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
            return response()->json([
                'status' => 'error',
                'message' => 'Erreur lors de la publication de la story : ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete a story (strictly authorized by owner).
     */
    public function destroy(Request $request, $id)
    {
        $loginUserId = $request->header('login_user_id') 
            ?? $request->query('login_user_id') 
            ?? $request->input('login_user_id') 
            ?? $request->user()?->id;

        $story = VendorStory::find($id);

        if (!$story) {
            return response()->json([
                'status' => 'error',
                'message' => 'Story introuvable.',
            ], 404);
        }

        // Strict ownership check
        if (empty($loginUserId) || (string)$story->user_id !== (string)$loginUserId) {
            return response()->json([
                'status' => 'error',
                'message' => 'Non autorisé à supprimer cette story.',
            ], 403);
        }

        // Delete media files from disk
        if (!empty($story->media_path)) {
            $fullMediaPath = public_path($story->media_path);
            if (File::exists($fullMediaPath)) {
                @unlink($fullMediaPath);
            }
        }

        if (!empty($story->thumbnail_path) && $story->thumbnail_path !== $story->media_path) {
            $fullThumbPath = public_path($story->thumbnail_path);
            if (File::exists($fullThumbPath)) {
                @unlink($fullThumbPath);
            }
        }

        // Delete view logs
        VendorStoryView::where('story_id', $story->id)->delete();

        $story->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Story supprimée.',
        ]);
    }

    /**
     * Record a story view.
     */
    public function view(Request $request, $id)
    {
        $story = VendorStory::find($id);
        if (!$story) {
            return response()->json(['status' => 'error', 'message' => 'Story introuvable'], 404);
        }

        $viewerUserId = $request->header('login_user_id') 
            ?? $request->input('login_user_id') 
            ?? $request->user()?->id;

        if (!empty($viewerUserId) && $viewerUserId !== 'nologinuser' && (string)$viewerUserId !== (string)$story->user_id) {
            $viewExists = VendorStoryView::where('story_id', $id)
                ->where('viewer_user_id', $viewerUserId)
                ->exists();

            if (!$viewExists) {
                VendorStoryView::create([
                    'story_id' => $id,
                    'viewer_user_id' => $viewerUserId,
                    'viewed_at' => Carbon::now(),
                ]);
                $story->increment('views_count');
            }
        }

        return response()->json([
            'status' => 'success',
            'views_count' => (int) $story->views_count,
        ]);
    }

    /**
     * Get active stories for a specific user (and their vendor if any).
     */
    public function userStories(Request $request, $userId)
    {
        $now = Carbon::now();
        $vendorId = Vendor::where('owner_user_id', $userId)->value('id');

        $stories = VendorStory::where('expires_at', '>', $now)
            ->where(function ($q) use ($userId, $vendorId) {
                $q->where('user_id', $userId);
                if (!empty($vendorId)) {
                    $q->orWhere('vendor_id', $vendorId);
                }
            })
            ->with(['user', 'vendor.logo', 'item.cover', 'item.currency'])
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => StoryApiResource::collection($stories),
            'count' => $stories->count(),
            'has_active_stories' => $stories->count() > 0,
            'latest_story_at' => $stories->max('created_at')?->format('Y-m-d H:i:s') ?? '',
        ]);
    }

    /**
     * Get active stories for a specific vendor (and its owner user).
     */
    public function vendorStories(Request $request, $vendorId)
    {
        $now = Carbon::now();
        $vendor = Vendor::find($vendorId);
        $ownerUserId = $vendor?->owner_user_id;

        $stories = VendorStory::where('expires_at', '>', $now)
            ->where(function ($q) use ($vendorId, $ownerUserId) {
                $q->where('vendor_id', $vendorId);
                if (!empty($ownerUserId)) {
                    $q->orWhere('user_id', $ownerUserId);
                }
            })
            ->with(['user', 'vendor.logo', 'item.cover', 'item.currency'])
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => StoryApiResource::collection($stories),
            'count' => $stories->count(),
            'has_active_stories' => $stories->count() > 0,
            'latest_story_at' => $stories->max('created_at')?->format('Y-m-d H:i:s') ?? '',
        ]);
    }
}
