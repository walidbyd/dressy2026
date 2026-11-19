<?php

namespace Modules\Core\Transformers\Api\App\V1_0\Notification;

use Illuminate\Http\Resources\Json\JsonResource;
use Modules\Core\Entities\Item;
use Modules\Core\Transformers\Api\App\V1_0\Product\ProductApiResource;
use Modules\Core\Transformers\Api\App\V1_0\User\UserApiResource;

class ChatHistoryApiResource extends JsonResource
{
    public function toArray($request)
    {
        $loginUserId = $request->query('login_user_id') 
            ?: ($request->user_id ?? $request->input('user_id') ?? (auth('sanctum')->check() ? auth('sanctum')->id() : null));

        $isSeller = ($loginUserId && (string) $this->seller_user_id === (string) $loginUserId);
        $role = $isSeller ? 'selling' : 'buying';

        // Dynamic unread count according to viewer's role
        $unreadCount = $isSeller 
            ? (int) (checkAndGetValue($this, 'seller_unread_count') ?? 0) 
            : (int) (checkAndGetValue($this, 'buyer_unread_count') ?? 0);

        // Counterparty user (buyer sees seller, seller sees buyer)
        $counterparty = $isSeller ? ($this->buyer ?? null) : ($this->seller ?? null);

        // Resolve item: direct item or order's item fallback
        $item = $this->item;
        if (!$item && $this->order && $this->order->orderItems && $this->order->orderItems->isNotEmpty()) {
            $item = $this->order->orderItems->first()->item;
        }

        // Resolve human-readable order status label
        $orderStatusLabel = '';
        if ($this->order && $this->order->orderStatus) {
            $orderStatusLabel = (string) $this->order->orderStatus->name;
        }
        if (empty($orderStatusLabel) && !empty($this->action_status)) {
            $statusMap = [
                'pending' => 'En attente',
                'confirmed' => 'Confirmée',
                'accepted' => 'Acceptée',
                'dispatched' => 'Expédiée',
                'shipped' => 'Expédiée',
                'delivered' => 'Livrée',
                'cancelled' => 'Annulée',
            ];
            $orderStatusLabel = $statusMap[strtolower($this->action_status)] ?? ucfirst($this->action_status);
        }

        $latestChatMessage = (string) checkAndGetValue($this, 'latest_chat_message');
        $chatDateStr = $this->getChatDateStr();

        return [
            'id' => (string) checkAndGetValue($this, 'id'),
            'item_id' => (string) checkAndGetValue($this, 'item_id'),
            'buyer_user_id' => (string) checkAndGetValue($this, 'buyer_user_id'),
            'seller_user_id' => (string) checkAndGetValue($this, 'seller_user_id'),
            'order_id' => (string) (checkAndGetValue($this, 'order_id') ?? ''),
            'order_code' => (string) (checkAndGetValue($this, 'order_code') ?? ''),
            'action_status' => (string) (checkAndGetValue($this, 'action_status') ?? 'none'),
            'order_status_label' => (string) $orderStatusLabel,
            'role' => (string) $role,
            'last_message' => $latestChatMessage,
            'last_message_time' => $chatDateStr,
            'unread_count' => (string) $unreadCount,
            'nego_price' => (string) checkAndGetValue($this, 'nego_price'),
            'buyer_unread_count' => (string) checkAndGetValue($this, 'buyer_unread_count'),
            'seller_unread_count' => (string) checkAndGetValue($this, 'seller_unread_count'),
            'latest_chat_message' => $latestChatMessage,
            'is_accept' => (string) checkAndGetValue($this, 'is_accept'),
            'offer_status' => (string) checkAndGetValue($this, 'offer_status'),
            'is_offer' => (string) $this->getOfferStatus(),
            'added_date' => (string) $this->getChatDate(),
            'offer_amount' => (string) checkAndGetValue($this, 'nego_price'),
            'item' => new ProductApiResource($item ?? []),
            'buyer' => new UserApiResource($this->buyer ?? []),
            'seller' => new UserApiResource($this->seller ?? []),
            'user' => new UserApiResource($counterparty ?? []),
            'added_date_str' => $chatDateStr,
            'is_empty_object' => $this->when(! isset($this->id), '1'),
        ];
    }

    // //////////////////////////////////////////////////////////////////
    // / Private Functions
    // //////////////////////////////////////////////////////////////////

    private function getChatDate()
    {
        $chat_date = '';
        if (isset($this->updated_date)) {
            $chat_date = $this->updated_date;
        } elseif (isset($this->added_date) && empty($this->updated_date)) {
            $chat_date = $this->added_date;
        }

        return $chat_date;
    }

    private function getChatDateStr()
    {
        $chatDateStr = '';
        if (! empty($this->getChatDate())) {
            $chatDateStr = $this->getChatDate()->diffForHumans();
        }

        return $chatDateStr;
    }

    private function getOfferStatus()
    {
        $is_sold_out = 0;
        if (isset($this->id)) {
            $item = Item::find($this->item_id);
            if ($item) {
                $is_sold_out = $item->is_sold_out;
            }
        } elseif (isset($this->chatItemId)) {
            $item = Item::find($this->chatItemId);
            if ($item) {
                $is_sold_out = $item->is_sold_out;
            }
            $this->item_id = $this->chatItemId;
            $this->item = $item;
        }

        if (empty($this->offer_status)) {
            return 0;
        }

        if ($this->offer_status == 2 || $is_sold_out == 1) {
            return 1;
        } else {
            return 0;
        }
    }
}
