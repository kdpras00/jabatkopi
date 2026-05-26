<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        // Seed Admin User
        User::factory()->create([
            'name' => 'Admin Jabat Kopi',
            'email' => 'admin@jabatkopi.com',
            'password' => bcrypt('password'),
            'role' => 'admin',
        ]);

        // Seed Pegawai User
        User::factory()->create([
            'name' => 'Pegawai Jabat Kopi',
            'email' => 'pegawai@jabatkopi.com',
            'password' => bcrypt('password'),
            'role' => 'pegawai',
        ]);
    }
}
