<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Modules\Core\Constants\Constants;

class RouteServiceProvider extends ServiceProvider
{
    /**
     * The path to the "home" route for your application.
     *
     * This is used by Laravel authentication to redirect users after login.
     *
     * @var string
     */
    public const HOME = '/admin';

    public static function getAppDir()
    {
        if (config('app.env') != 'local') {
            return config('app.dir');
        } else {
            return '';
        }
    }

    public static function getRoot()
    {
        if (Auth::check()) {
            $user = Auth::user();
            if ($user && ($user->role_id == 1 || $user->role_id == Constants::superAdminRoleId || checkForDashboardPermission() || ($user->role_id && $user->role_id != Constants::normalUserRoleId))) {
                return RouteServiceProvider::getAppDir().'/admin';
            }
        }

        $home = '/';

        return RouteServiceProvider::getAppDir().$home;
    }

    /**
     * Define your route model bindings, pattern filters, etc.
     *
     * @return void
     */
    public function boot()
    {
        $this->configureRateLimiting();

        $this->routes(function () {
            Route::prefix(App::environment('production') ? config('app.dir').'/api' : 'api')
                ->middleware('api')
                ->group(base_path('routes/api.php'));

            Route::prefix(App::environment('production') ? config('app.dir').'/api/v1.0' : 'api/v1.0')
                // ->middleware(['api', 'checkSupportedApiVersion:1.0'])
                ->middleware(['api'])
                ->group(base_path('routes/api_v1_0.php'));

            Route::prefix(App::environment('production') ? config('app.dir') : '')
                ->middleware('web')
                ->namespace($this->namespace)
                ->group(base_path('routes/web.php'));
            // Route::middleware('web')
            //     ->group(base_path('routes/web.php'));
        });
    }

    /**
     * Configure the rate limiters for the application.
     *
     * @return void
     */
    protected function configureRateLimiting()
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(200)->by($request->user()?->id ?: $request->ip());
        });
    }
}
