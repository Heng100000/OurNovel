<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$u = \App\Models\User::first();
\Illuminate\Support\Facades\Auth::login($u);
$c = new \App\Http\Controllers\Api\CartItemController();
$data = $c->index()->getData();
echo json_encode($data, JSON_PRETTY_PRINT);
