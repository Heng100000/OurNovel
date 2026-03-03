import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Shop from './pages/Shop';
import Login from './pages/Login';
import Checkout from './pages/Checkout';

const App: React.FC = () => {
    return (
        <BrowserRouter>
            <div className="min-h-screen bg-slate-50">
                <Routes>
                    <Route path="/shop" element={<Shop />} />
                    <Route path="/shop/checkout" element={<Checkout />} />
                    <Route path="/shop/login" element={<Login />} />
                    {/* Catch all other shop paths and redirect to main shop for now */}
                    <Route path="/shop/*" element={<Navigate to="/shop" replace />} />
                </Routes>
            </div>
        </BrowserRouter>
    );
};

export default App;
