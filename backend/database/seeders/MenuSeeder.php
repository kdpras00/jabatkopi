<?php

namespace Database\Seeders;

use App\Models\Menu;
use Illuminate\Database\Seeder;

class MenuSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $menus = [
            ['name' => 'Nasi goreng', 'category' => 'Food & Snack', 'price' => 35000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Cireng Sambal Rujak', 'category' => 'food', 'price' => 20000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Jabat Fries', 'category' => 'Food & Snack', 'price' => 20000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Choco Banana', 'category' => 'Food & Snack', 'price' => 20000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Crunchy Donuts (1 Pcs)', 'category' => 'Food & Snack', 'price' => 10000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Donat Gula (1 Pcs)', 'category' => 'Food & Snack', 'price' => 6000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Roti Bakar', 'category' => 'Food & Snack', 'price' => 23000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Katela Goreng', 'category' => 'Food & Snack', 'price' => 20000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Ayam Goreng Ibu', 'category' => 'Food & Snack', 'price' => 23000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Chocolate (Hot)', 'category' => 'Non Coffee', 'price' => 24000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Chocolate (Ice)', 'category' => 'Non Coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Chocolate Latte (Hot)', 'category' => 'Non Coffee', 'price' => 24000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Chocolate Latte (Ice)', 'category' => 'Non Coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Matcha Latte (Hot)', 'category' => 'Non Coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Matcha Latte (Ice)', 'category' => 'Non Coffee', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Tropical Tea', 'category' => 'Non Coffee', 'price' => 30000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Lychee Tea', 'category' => 'Tea', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Pour Over (Hot)', 'category' => 'Manual Brew', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Tubruk (Hot)', 'category' => 'Manual Brew', 'price' => 20000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Japanese (Ice)', 'category' => 'Manual Brew', 'price' => 28000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Espresso (Hot)', 'category' => 'Coffee', 'price' => 22000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Picollo (Hot)', 'category' => 'Coffee', 'price' => 27000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Cafe Latte (Hot)', 'category' => 'Coffee', 'price' => 32000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Cafe Latte (Ice)', 'category' => 'Coffee', 'price' => 32000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Caramel Latte (Hot)', 'category' => 'Coffee', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Caramel Latte (Ice)', 'category' => 'Coffee', 'price' => 27000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Hazelnut Latte (Hot)', 'category' => 'Coffee', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Hazelnut Latte (Ice)', 'category' => 'Coffee', 'price' => 27000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Cafe Mocha (Hot)', 'category' => 'Coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Cafe Mocha (Ice)', 'category' => 'Coffee', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Cappuccino (Hot)', 'category' => 'Coffee', 'price' => 33000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Cappuccino (Ice)', 'category' => 'Coffee', 'price' => 33000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Velvet Latte (Ice)', 'category' => 'Non Coffee', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Chocolate Frappe', 'category' => 'Non Coffee', 'price' => 30000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Velvet Frappe', 'category' => 'Non Coffee', 'price' => 30000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Matcha Cream', 'category' => 'Non Coffee', 'price' => 27000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Creamy Yakult', 'category' => 'Non Coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Pandan Latte', 'category' => 'Non Coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Mineral Water (Hot)', 'category' => 'Non Coffee', 'price' => 10000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Mineral Water (Ice)', 'category' => 'Non Coffee', 'price' => 10000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Lemon Tea (Hot)', 'category' => 'Tea', 'price' => 20000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Lemon Tea (Ice)', 'category' => 'Tea', 'price' => 21000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Citron Tea (Hot)', 'category' => 'Tea', 'price' => 21000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Citron Tea (Ice)', 'category' => 'Tea', 'price' => 23000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Peppermint Tea (Hot)', 'category' => 'Tea', 'price' => 18000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Peppermint Tea (Ice)', 'category' => 'Tea', 'price' => 20000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Thai Tea', 'category' => 'Tea', 'price' => 23000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Long Black (Hot)', 'category' => 'Coffee', 'price' => 24000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Long Black (Ice)', 'category' => 'Coffee', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Sanger (Hot)', 'category' => 'Coffee', 'price' => 22000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Sanger (Ice)', 'category' => 'Coffee', 'price' => 23000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Sally Cinnamon (Hot)', 'category' => 'Coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Sally Cinnamon (Ice)', 'category' => 'Coffee', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Affogato', 'category' => 'Coffee', 'price' => 30000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Cafe Lemonade', 'category' => 'Coffee', 'price' => 23000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Kopi Susu Gula Aren', 'category' => 'Coffee', 'price' => 26000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Kopi Susu Jabat', 'category' => 'Coffee', 'price' => 24000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Kawista Coffee Cream', 'category' => 'Coffee', 'price' => 28000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Spanish Latte', 'category' => 'Coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Jabat Frappe', 'category' => 'Coffee', 'price' => 33000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Americano', 'category' => 'Coffee', 'price' => 20000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'testing', 'category' => 'coffee', 'price' => 1000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
            ['name' => 'Velvet (Hot)', 'category' => 'non-coffee', 'price' => 25000, 'image_url' => 'public/storage/images/default-menu.png', 'is_available' => true, 'stock' => 100],
        ];

        foreach ($menus as $menu) {
            Menu::create($menu);
        }
    }
}
