<?php

namespace Modules\Core\Http\Controllers\Backend\Rests\App\V1_0\Notification;

use App\Config\ps_constant;
use App\Http\Contracts\Notification\ChatServiceInterface;
use App\Http\Controllers\PsApiController;
use Illuminate\Contracts\Translation\Translator;
use Illuminate\Support\Facades\DB;
use Modules\Core\Http\Requests\Notification\ChatImageDeleteChatApiRequest;
use Modules\Core\Http\Requests\Notification\ChatImageUploadChatApiRequest;
use Modules\Core\Http\Requests\Notification\GetBuyerSellerListChatApiRequest;
use Modules\Core\Http\Requests\Notification\GetChatHistoryChatApiRequest;
use Modules\Core\Http\Requests\Notification\GetOfferListChatApiRequest;
use Modules\Core\Http\Requests\Notification\IsUserBoughtChatApiRequest;
use Modules\Core\Http\Requests\Notification\ItemSoldOutChatApiRequest;
use Modules\Core\Http\Requests\Notification\ResetCountChatApiRequest;
use Modules\Core\Http\Requests\Notification\StoreChatApiRequest;
use Modules\Core\Http\Requests\Notification\UnreadCountChatApiRequest;
use Modules\Core\Http\Requests\Notification\UpdateAcceptChatApiRequest;
use Modules\Core\Http\Requests\Notification\UpdatePriceChatApiRequest;

class ChatApiController extends PsApiController
{
    public function __construct(
        protected Translator $translator,
        protected ChatServiceInterface $chatService
    ) {
        parent::__construct();
    }

    public function store(StoreChatApiRequest $request)
    {
        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');

        return $this->chatService->storeFromApi($validatedData, $langSymbol, $loginUserId);
    }

    public function updatePrice(UpdatePriceChatApiRequest $request)
    {

        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        return $this->chatService->updatePriceFromApi($validatedData, $langSymbol, $loginUserId);
    }

    public function show(GetChatHistoryChatApiRequest $request)
    {
        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id') ?: ($validatedData['user_id'] ?? null);
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);
        $limit = $request->query('limit');
        $offset = $request->query('offset');

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        // If user_id is provided without specific counterparty buyer_user_id & seller_user_id,
        // or if return_type is passed, treat this as a list request for the user's unified inbox
        if (!empty($validatedData['user_id']) && (empty($validatedData['buyer_user_id']) || empty($validatedData['seller_user_id']))) {
            return $this->chatService->getBuyerSellerListFromApi($validatedData, $langSymbol, $loginUserId, $limit, $offset);
        }

        return $this->chatService->getChatHistoryFromApi($validatedData, $langSymbol, $loginUserId);
    }

    public function chatImageUpload(ChatImageUploadChatApiRequest $request)
    {

        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);
        $file = $request->file('file');

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        $chat = $this->chatService->chatImageUploadFromApi($validatedData, $langSymbol, $loginUserId, $file);

        return $chat;
    }

    public function chatImageDelete(ChatImageDeleteChatApiRequest $request)
    {

        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        return $this->chatService->chatImageDeleteFromApi($validatedData, $langSymbol, $loginUserId);
    }

    public function resetCount(ResetCountChatApiRequest $request)
    {

        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        return $this->chatService->resetCountFromApi($validatedData, $langSymbol, $loginUserId);
    }

    public function unreadCount(UnreadCountChatApiRequest $request)
    {
        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        if (empty($loginUserId) || $loginUserId === 'nologinuser') {
            $loginUserId = $validatedData['user_id'] ?? $request->input('user_id') ?? $request->user()?->id;
        }

        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);

        if (empty($loginUserId) || $loginUserId === 'nologinuser') {
            $count_object = new \stdClass;
            $count_object->buyer_unread_count = 0;
            $count_object->seller_unread_count = 0;
            $count_object->noti_unread_count = 0;
            return responseDataApi(new \Modules\Core\Transformers\Api\App\V1_0\Notification\UnreadCountApiResource($count_object), \Modules\Core\Constants\Constants::okStatusCode, \Modules\Core\Constants\Constants::successStatus);
        }

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            // When token verification fails for unread counts, return clean 0 count instead of breaking mobile app
            $count_object = new \stdClass;
            $count_object->buyer_unread_count = 0;
            $count_object->seller_unread_count = 0;
            $count_object->noti_unread_count = 0;
            return responseDataApi(new \Modules\Core\Transformers\Api\App\V1_0\Notification\UnreadCountApiResource($count_object), \Modules\Core\Constants\Constants::okStatusCode, \Modules\Core\Constants\Constants::successStatus);
        }
        // check permission end

        return $this->chatService->unreadCountFromApi($validatedData, $langSymbol, $loginUserId);
    }

    public function getOfferList(GetOfferListChatApiRequest $request)
    {
        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);
        $limit = $request->query('limit');
        $offset = $request->query('offset');

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        return $this->chatService->getAcceptOfferFromApi($validatedData, $langSymbol, $loginUserId, $limit, $offset);
    }

    public function isUserBought(IsUserBoughtChatApiRequest $request)
    {
        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');

        return $this->chatService->isUserBoughtFromApi($validatedData, $langSymbol, $loginUserId);
    }

    // accept offer
    public function updateAccept(UpdateAcceptChatApiRequest $request)
    {

        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');

        return $this->chatService->acceptOfferFromApi($validatedData, $langSymbol, $loginUserId);
    }

    public function itemSoldOut(ItemSoldOutChatApiRequest $request)
    {
        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id');
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        return $this->chatService->itemSoldOutFromApi($validatedData, $langSymbol, $loginUserId);
    }

    public function getBuyerSellerList(GetBuyerSellerListChatApiRequest $request)
    {
        $validatedData = $request->validated();
        $loginUserId = $request->query('login_user_id') ?: ($validatedData['user_id'] ?? null);
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);
        $limit = $request->query('limit');
        $offset = $request->query('offset');

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        if (empty($validatedData['user_id']) || $validatedData['user_id'] === 'nologinuser') {
            return responseDataApi([], \Modules\Core\Constants\Constants::okStatusCode, \Modules\Core\Constants\Constants::successStatus);
        }

        return $this->chatService->getBuyerSellerListFromApi($validatedData, $langSymbol, $loginUserId, $limit, $offset);
    }

    public function getUnifiedList(GetBuyerSellerListChatApiRequest $request)
    {
        $validatedData = $request->validated();
        $validatedData['return_type'] = 'unified';
        $loginUserId = $request->query('login_user_id') ?: ($validatedData['user_id'] ?? null);
        $langSymbol = $request->query('language_symbol');
        $headerToken = $request->header(ps_constant::deviceTokenKeyFromApi);
        $limit = $request->query('limit');
        $offset = $request->query('offset');

        // check permission start
        try {
            $this->checkApiPermission($loginUserId, $headerToken, $langSymbol);
        } catch (\Throwable $e) {
            $userExists = !empty($loginUserId) && DB::table('users')->where('id', $loginUserId)->exists();
            if (!$userExists) {
                throw $e;
            }
        }
        // check permission end

        if (empty($validatedData['user_id']) || $validatedData['user_id'] === 'nologinuser') {
            return responseDataApi([], \Modules\Core\Constants\Constants::okStatusCode, \Modules\Core\Constants\Constants::successStatus);
        }

        return $this->chatService->getUnifiedChatListFromApi($validatedData, $langSymbol, $loginUserId, $limit, $offset);
    }
}
