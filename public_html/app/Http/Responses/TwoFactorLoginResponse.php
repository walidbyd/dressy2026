<?php

namespace App\Http\Responses;

use App\Providers\RouteServiceProvider;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Laravel\Fortify\Contracts\TwoFactorLoginResponse as TwoFactorLoginResponseContract;
use Modules\Core\Constants\Constants;

class TwoFactorLoginResponse implements TwoFactorLoginResponseContract
{
    /**
     * Create an HTTP response that represents the object.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Symfony\Component\HttpFoundation\Response
     */
    public function toResponse($request)
    {
        if ($request->wantsJson()) {
            return new JsonResponse('', 204);
        }

        if (Auth::check()) {
            $user = Auth::user();
            if ($user->role_id == 1 || $user->role_id == Constants::superAdminRoleId || checkForDashboardPermission() || ($user->role_id && $user->role_id != Constants::normalUserRoleId)) {
                $intended = session()->get('url.intended');
                if (empty($intended) || $intended == url('/') || $intended == url('/login') || str_ends_with(rtrim($intended, '/'), '/login') || rtrim($intended, '/') == rtrim(url('/'), '/')) {
                    session()->forget('url.intended');
                    return redirect()->route('admin.index');
                }
                return redirect()->intended(route('admin.index'));
            }
        }

        return redirect()->intended(RouteServiceProvider::getRoot());
    }
}
