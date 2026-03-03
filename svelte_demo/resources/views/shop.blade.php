<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>OurNovel Store | React</title>
        @viteReactRefresh
        @vite(['resources/css/app.css', 'resources/js/react/main.tsx'])
    </head>
    <body class="antialiased">
        <div id="app"></div>
    </body>
</html>
