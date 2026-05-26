<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Menu extends Model
{
    use SoftDeletes;

    protected $table = 'menus';

    protected $fillable = [
        'name',
        'category',
        'price',
        'image_url',
        'is_available',
        'stock',
        'description',
    ];

    protected $casts = [
        'price' => 'float',
        'is_available' => 'boolean',
        'stock' => 'integer',
    ];
}
