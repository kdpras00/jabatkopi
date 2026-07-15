<?php

namespace Database\Seeders;

use App\Models\Table;
use Illuminate\Database\Seeder;

class TableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tables = [
            ['qr_code_ref' => 'JK-TABLE-01', 'capacity' => 2, 'status' => 'available'],
            ['qr_code_ref' => 'JK-TABLE-02', 'capacity' => 2, 'status' => 'available'],
            ['qr_code_ref' => 'JK-TABLE-03', 'capacity' => 4, 'status' => 'available'],
            ['qr_code_ref' => 'JK-TABLE-04', 'capacity' => 4, 'status' => 'available'],
            ['qr_code_ref' => 'JK-TABLE-05', 'capacity' => 6, 'status' => 'available'],
        ];

        foreach ($tables as $table) {
            Table::create($table);
        }
    }
}
