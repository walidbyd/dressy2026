<?php

namespace Modules\Core\Http\Requests\Notification;

use App\Exceptions\PsApiException;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Arr;

class GetChatHistoryChatApiRequest extends FormRequest
{
    protected function prepareForValidation()
    {
        if (empty($this->user_id) && !empty($this->query('login_user_id')) && $this->query('login_user_id') !== 'nologinuser') {
            $this->merge([
                'user_id' => $this->query('login_user_id'),
            ]);
        }
    }

    public function rules()
    {
        return [
            'user_id' => 'nullable',
            'return_type' => 'nullable|string',
            'item_id' => 'nullable',
            'order_id' => 'nullable',
            'order_code' => 'nullable',
            'buyer_user_id' => 'nullable',
            'seller_user_id' => 'nullable',
        ];
    }

    public function failedValidation(Validator $validator)
    {
        throw new PsApiException(
            implode("\n", Arr::flatten($validator->getMessageBag()->getMessages()))
        );
    }

    public function authorize()
    {
        return true;
    }
}
