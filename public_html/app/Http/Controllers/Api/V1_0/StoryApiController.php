<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Http\Resources\StoryApiResource;
use App\Models\VendorStory;
use App\Models\VendorStoryView;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Validator;
use Modules\Core\Entities\Vendor\Vendor;

class StoryApiController extends Controller
{
    /**
     * Get active 24h stories feed.
     */
    public function feed(Request $request)
    {
        $loginUserId = $request->header('login_user_id') 
            ?? $request->query('login_user_id') 
            ?? $request->input('login_user_id') 
            ?? $request->user()?->id;

        $now = Carbon::now();

        $activeStories = VendorStory::where('expires_at', '>', $now)
            ->with(['user', 'vendor.logo', 'item.defaultPhoto', 'item.itemCurrency'])
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

            // Grouping key: vendor_id if exists, otherwise "user_" . user_id
            $groupKey = $story->vendor_id ? 'vendor_' . $story->vendor_id : 'user_' . $story->user_id;

            if (!isset($vendorsMap[$groupKey])) {
                $user = $story->user;
                $vendor = $story->vendor;
                $vendorName = $vendor?->name ?? $user?->name ?? 'Dressy Vendeur';
                $vendorLogo = '';
                if ($vendor?->logo?->img_path) {
                    $vendorLogo = asset('storage/uploads/' . $vendor->logo->img_path);
                } elseif ($user?->user_cover_photo) {
                    $vendorLogo = asset('storage/uploads/' . $user->user_cover_photo);
                }

                $vendorsMap[$groupKey] = [
                    'group_key' => $groupKey,
                    'vendor_id' => $story->vendor_id ? (string) $story->vendor_id : '',
                    'vendor_user_id' => (string) $story->user_id,
                    'vendor_name' => $vendorName,
                    'vendor_logo' => $vendorLogo,
                    'is_mine' => $isMine,
                    'has_unseen' => true,
                    'stories' => [],
                ];
            }

            $vendorsMap[$groupKey]['stories'][] = new StoryApiResource($story);
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'my_stories' => $myStories,
                'stories_by_vendor' => array_values($vendorsMap),
                'total_active' => $activeStories->count(),
            ],
        ]);
    }

    /**
     * Upload a new story slide (photo or video).
     */
    public function upload(Request $request)
    {
        $loginUserId = $request->header('login_user_id') 
            ?? $request->input('login_user_id') 
            ?? $request->user()?->id;

        if (empty($loginUserId) || $loginUserId === 'nologinuser') {
            return response()->json([
                'status' => 'error',
                'message' => 'Authentification requise pour publier une story.',
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'media_file' => 'required_without:media_path|file|max:25600', // max 25MB
            'caption' => 'nullable|string|max:500',
            'item_id' => 'nullable',
            'filter_preset' => 'nullable|string|max:32',
            'media_type' => 'nullable|string|in:image,video',
            'duration' => 'nullable|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], 422);
        }

        // Detect vendor profile if user owns one
        $vendor = Vendor::where('owner_user_id', $loginUserId)->first();

        $mediaType = $request->input('media_type', 'image');
        $mediaPath = '';
        $thumbnailPath = '';

        $storiesDir = public_path('uploads/stories');
        if (!File::isDirectory($storiesDir)) {
            File::makeDirectory($storiesDir, 0755, true, true);
        }

        if ($request->hasFile('media_file')) {
            $file = $request->file('media_file');
            $extension = strtolower($file->getClientOriginalExtension());
            if (in_array($extension, ['mp4', 'mov', 'avi', 'm4v', 'webm'])) {
                $mediaType = 'video';
            } else {
                $mediaType = 'image';
            }

            $fileName = 'story_' . $loginUserId . '_' . time() . '_' . uniqid() . '.' . $extension;
            $file->move($storiesDir, $fileName);
            $mediaPath = 'uploads/stories/' . $fileName;
        } elseif ($request->filled('media_path')) {
            $mediaPath = $request->input('media_path');
        }

        if ($request->hasFile('thumbnail_file')) {
            $thumb = $request->file('thumbnail_file');
            $thumbName = 'thumb_' . $loginUserId . '_' . time() . '_' . uniqid() . '.' . strtolower($thumb->getClientOriginalExtension());
            $thumb->move($storiesDir, $thumbName);
            $thumbnailPath = 'uploads/stories/' . $thumbName;
        } elseif ($mediaType === 'image') {
            $thumbnailPath = $mediaPath;
        }

        $duration = (int) $request->input('duration', ($mediaType === 'video' ? 15 : 5));
        $filterPreset = $request->input('filter_preset', 'original');

        $story = VendorStory::create([
            'user_id' => $loginUserId,
            'vendor_id' => $vendor?->id,
            'media_type' => $mediaType,
            'media_path' => $mediaPath,
            'thumbnail_path' => $thumbnailPath,
            'caption' => $request->input('caption'),
            'item_id' => $request->input('item_id') ? (int) $request->input('item_id') : null,
            'filter_preset' => $filterPreset,
            'views_count' => 0,
            'duration' => $duration,
            'expires_at' => Carbon::now()->addHours(24),
            'added_date' => Carbon::now(),
            'added_user_id' => $loginUserId,
        ]);

        $story->load(['user', 'vendor.logo', 'item.defaultPhoto', 'item.itemCurrency']);

        return response()->json([
            'status' => 'success',
            'message' => 'Story publiée avec succès.',
            'data' => new StoryApiResource($story),
        ]);
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
     * Get active stories for a specific user or vendor.
     */
    public function userStories(Request $request, $userId)
    {
        $now = Carbon::now();
        $stories = VendorStory::where('expires_at', '>', $now)
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhere('vendor_id', $userId);
            })
            ->with(['user', 'vendor.logo', 'item.defaultPhoto', 'item.itemCurrency'])
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => StoryApiResource::collection($stories),
            'count' => $stories->count(),
        ]);
    }
}
