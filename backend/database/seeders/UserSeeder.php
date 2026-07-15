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
        $admin = User::create([
            'name' => 'Admin Jabat Kopi',
            'email' => 'admin@jabatkopi.com',
            'password' => bcrypt('password'),
            'email_verified_at' => now(),
        ]);
        $admin->assignRole('admin');

        // Seed Pegawai User
        $pegawai = User::create([
            'name' => 'Pegawai Jabat Kopi',
            'email' => 'pegawai@jabatkopi.com',
            'password' => bcrypt('password'),
            'email_verified_at' => now(),
        ]);
        $pegawai->assignRole('pegawai');

        // Seed Customer User
        $customer = User::create([
            'name' => 'Customer Jabat Kopi',
            'email' => 'customer@jabatkopi.com',
            'password' => bcrypt('password'),
            'email_verified_at' => now(),
        ]);
        $customer->assignRole('customer');
    }
}
