<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class MigrateFreshKeepUsers extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'migrate:fresh-keep-users {--seed : Indicates if the seed task should be re-run}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Drop all tables and re-run all migrations, but retain the users table data.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Backing up users...');

        try {
            $users = \App\Models\User::all()->toArray();
        } catch (\Exception $e) {
            $this->error('Could not backup users. Does the table exist?');
            $users = [];
        }

        $this->info('Running migrate:fresh...');

        $params = ['--force' => true];
        if ($this->option('seed')) {
            $params['--seed'] = true;
        }

        $this->call('migrate:fresh', $params);

        if (! empty($users)) {
            $this->info('Restoring '.count($users).' users...');
            \Illuminate\Support\Facades\DB::table('users')->insert($users);
            $this->info('Users restored successfully!');
        } else {
            $this->warn('No users were backed up or restored.');
        }
    }
}
