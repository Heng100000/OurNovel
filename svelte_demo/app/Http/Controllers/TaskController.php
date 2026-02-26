<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\Task;

class TaskController extends Controller
{
    public function index() {
        $tasks = Task::latest()->get();
        return Inertia::render('Task/Index', [
            'tasks' => $tasks,
        ]);
    }
    public function store(Request $request) {
        $request->validate([
            'title' => 'required',
        ]);
        Task::create([
            'title' => $request->title,
        ]);
        return redirect()->back();  
    }
}
