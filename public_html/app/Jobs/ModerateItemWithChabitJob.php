<?php

namespace App\Jobs;

use App\Services\Chabit\ChabitItemModerator;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ModerateItemWithChabitJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;

    public int $timeout = 60;

    public function __construct(public int $itemId) {}

    public function handle(ChabitItemModerator $moderator): void
    {
        $moderator->moderateItem($this->itemId);
    }
}
