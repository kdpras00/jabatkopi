<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MenuController extends Controller
{
    public function index()
    {
        $menus = DB::table('menus')->whereNull('deleted_at')->orderBy('name')->get();
        // Rewrite image URL ke server yang sedang aktif (local atau production)
        // sehingga tidak ada cross-origin redirect antar environment
        foreach ($menus as $menu) {
            if ($menu->image_url) {
                $filename = basename(parse_url($menu->image_url, PHP_URL_PATH));
                $menu->image_url = url('/api/images/menus/' . $filename);
            }
        }
        return response()->json(['status' => 200, 'message' => 'Success', 'data' => $menus]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
        ]);

        $imageUrl = $request->image_url ?? '';

        // Check if image_base64 is sent
        if ($request->has('image_base64') && !empty($request->image_base64)) {
            $imageParts = explode(";base64,", $request->image_base64);
            $imageTypeAux = explode("image/", $imageParts[0]);
            $imageType = count($imageTypeAux) > 1 ? $imageTypeAux[1] : null;
            
            if (!in_array($imageType, ['jpeg', 'jpg', 'png'])) {
                return response()->json(['message' => 'Tipe gambar tidak valid. Hanya menerima format JPG, JPEG, dan PNG.'], 400);
            }
            
            $imageBase64 = base64_decode(count($imageParts) > 1 ? $imageParts[1] : $imageParts[0]);
            
            $fileName = Str::uuid() . '.' . $imageType;
            Storage::disk('public')->put('menus/' . $fileName, $imageBase64);
            $imageUrl = url('storage/menus/' . $fileName);
        }

        $id = DB::table('menus')->insertGetId([
            'name' => $request->name,
            'category' => $request->category,
            'price' => $request->price,
            'image_url' => $imageUrl,
            'is_available' => $request->is_available ?? true,
            'stock' => $request->stock ?? 50,
            'description' => $request->description ?? '',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $menu = DB::table('menus')->where('id', $id)->first();
        return response()->json(['status' => 201, 'message' => 'Menu created', 'data' => $menu]);
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
        ]);

        $updateData = [
            'name' => $request->name,
            'category' => $request->category,
            'price' => $request->price,
            'is_available' => $request->is_available ?? true,
            'stock' => $request->stock ?? 50,
            'description' => $request->description ?? '',
            'updated_at' => now(),
        ];

        if ($request->has('image_base64') && !empty($request->image_base64)) {
            $imageParts = explode(";base64,", $request->image_base64);
            $imageTypeAux = explode("image/", $imageParts[0]);
            $imageType = count($imageTypeAux) > 1 ? $imageTypeAux[1] : null;
            
            if (!in_array($imageType, ['jpeg', 'jpg', 'png'])) {
                return response()->json(['message' => 'Tipe gambar tidak valid. Hanya menerima format JPG, JPEG, dan PNG.'], 400);
            }
            
            $imageBase64 = base64_decode(count($imageParts) > 1 ? $imageParts[1] : $imageParts[0]);
            
            $fileName = Str::uuid() . '.' . $imageType;
            Storage::disk('public')->put('menus/' . $fileName, $imageBase64);
            $updateData['image_url'] = url('storage/menus/' . $fileName);
        } else if ($request->has('image_url')) {
            $updateData['image_url'] = $request->image_url;
        }

        DB::table('menus')->where('id', $id)->update($updateData);
        $menu = DB::table('menus')->where('id', $id)->first();

        return response()->json(['status' => 200, 'message' => 'Menu updated', 'data' => $menu]);
    }

    public function destroy($id)
    {
        DB::table('menus')->where('id', $id)->update(['deleted_at' => now()]);
        return response()->json(['status' => 200, 'message' => 'Menu deleted']);
    }
}
