<?php

namespace App\Console;

use App\Console\Commands\CancelExpiredOrdersCommand;
use App\Console\Commands\GenerateSitemap;
use App\Console\Commands\DressyCleanProduction;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected $commands = [
        GenerateSitemap::class,
        DressyCleanProduction::class,
        CancelExpiredOrdersCommand::class,
    ];

    /**
     * Define the application's command schedule.
     *
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        $schedule->command('sitemap:generate')->daily();
        $schedule->command('orders:cancel-expired')->everyFifteenMinutes();
        // $schedule->command('sitemap:generate')->everyMinute();

    }

    /**
     * Register the commands for the application.
     *
     * @return void
     */
    protected function commands()
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
