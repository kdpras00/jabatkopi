<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Seed Admin User
        $admin = User::factory()->create([
            'name' => 'Admin Jabat Kopi',
            'email' => 'admin@jabatkopi.com',
            'password' => bcrypt('password'),
        ]);
        $admin->assignRole('admin');

        // Seed Pegawai User
        $pegawai = User::factory()->create([
            'name' => 'Pegawai Jabat Kopi',
            'email' => 'pegawai@jabatkopi.com',
            'password' => bcrypt('password'),
        ]);
        $pegawai->assignRole('pegawai');

        // Seed Customer User
        $customer = User::factory()->create([
            'name' => 'Customer Jabat Kopi',
            'email' => 'customer@jabatkopi.com',
            'password' => bcrypt('password'),
        ]);
        $customer->assignRole('customer');
    }
}
