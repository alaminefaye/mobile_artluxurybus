<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function index()
    {
        return view('settings.index');
    }

    public function update(Request $request)
    {
        // Logique de mise à jour des paramètres
        return redirect()->back()->with('success', 'Paramètres mis à jour');
    }
}
