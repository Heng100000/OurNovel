import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate, Link } from 'react-router-dom';
import { LogIn, Lock, Eye, EyeOff, BookOpen, User } from 'lucide-react';

const Login: React.FC = () => {
    const [identifier, setIdentifier] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const navigate = useNavigate();

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);

        try {
            const response = await axios.post('/api/login', { identifier, password });
            if (response.data.access_token) {
                localStorage.setItem('auth_token', response.data.access_token);
                localStorage.setItem('user', JSON.stringify(response.data.user));
            }
            navigate('/shop');
        } catch (err: any) {
            setError(err.response?.data?.message || 'Login failed. Please check your credentials.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-white px-6 py-12 font-sans text-slate-900">
            <div className="w-full max-w-md">
                <div className="text-center mb-10">
                    <h1 className="text-4xl font-extrabold text-[#1a1c3d] mb-3">Welcome Back</h1>
                    <p className="text-slate-500 font-medium">Enter your credentials to access your account</p>
                </div>

                {/* Social Login Buttons */}
                <div className="flex gap-4 mb-10">
                    <button className="flex-1 flex justify-center items-center py-4 px-4 border border-slate-100 rounded-2xl hover:bg-slate-50 transition-all shadow-sm">
                        <svg className="w-6 h-6" viewBox="0 0 24 24">
                            <path fill="#EA4335" d="M12.48 10.92v3.28h7.84c-.24 1.84-.96 3.4-2.16 4.56a8.88 8.88 0 0 1-5.68 2.16c-4.88 0-8.88-4-8.88-8.88s4-8.88 8.88-8.88c2.4 0 4.56.88 6.16 2.48l2.32-2.32A11.97 11.97 0 0 0 12.48 1c-6.64 0-12 5.36-12 12s5.36 12 12 12c3.2 0 6.16-1.12 8.4-3.12 2.32-2.08 3.76-5.12 3.76-8.88 0-.64-.08-1.28-.24-1.84h-11.92z" />
                        </svg>
                    </button>
                    <button className="flex-1 flex justify-center items-center py-4 px-4 border border-slate-100 rounded-2xl hover:bg-slate-50 transition-all shadow-sm">
                        <svg className="w-6 h-6" fill="#1877F2" viewBox="0 0 24 24">
                            <path d="M24 12.07C24 5.41 18.63 0 12 0S0 5.4 0 12.07C0 18.1 4.39 23.1 10.13 24v-8.44H7.08v-3.49h3.05V9.41c0-3.01 1.79-4.67 4.52-4.67 1.31 0 2.68.23 2.68.23v2.95h-1.5c-1.49 0-1.96.93-1.96 1.88v2.26h3.32l-.53 3.49h-2.79V24C19.61 23.1 24 18.1 24 12.07z" />
                        </svg>
                    </button>
                    <button className="flex-1 flex justify-center items-center py-4 px-4 border border-slate-100 rounded-2xl hover:bg-slate-50 transition-all shadow-sm">
                        <svg className="w-6 h-6" fill="#5865F2" viewBox="0 0 24 24">
                            <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037 19.736 19.736 0 0 0-4.885 1.515.069.069 0 0 0-.032.027C.533 9.048-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.419-2.157 2.419zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.419-2.157 2.419z" />
                        </svg>
                    </button>
                </div>

                <div className="relative flex items-center mb-10">
                    <div className="flex-grow border-t border-slate-100"></div>
                    <span className="flex-shrink mx-4 text-slate-400 font-medium text-sm">or</span>
                    <div className="flex-grow border-t border-slate-100"></div>
                </div>

                {error && (
                    <div className="mb-6 p-4 bg-rose-50 border border-rose-100 text-rose-600 rounded-2xl text-sm font-bold flex items-center animate-in fade-in slide-in-from-top-2">
                        <span>{error}</span>
                    </div>
                )}

                <form onSubmit={handleLogin} className="space-y-8">
                    <div className="space-y-2 text-left">
                        <label className="block text-sm font-bold text-slate-700 ml-1">Email address</label>
                        <input
                            type="text"
                            required
                            className="w-full px-5 py-4 bg-white border border-slate-200 rounded-2xl focus:border-[#6366f1] focus:ring-4 focus:ring-[#6366f1]/5 transition-all outline-none font-medium text-slate-700 placeholder:text-slate-300 shadow-sm"
                            placeholder="rafiqur51@company.com"
                            value={identifier}
                            onChange={(e) => setIdentifier(e.target.value)}
                        />
                    </div>

                    <div className="space-y-2 text-left relative">
                        <div className="flex justify-between items-center mb-1">
                            <label className="block text-sm font-bold text-slate-700 ml-1">Password</label>
                            <a href="#" className="text-sm font-bold text-[#6366f1] hover:text-[#4f46e5] transition-colors">Forgot password?</a>
                        </div>
                        <div className="relative group">
                            <input
                                type={showPassword ? "text" : "password"}
                                required
                                className="w-full px-5 py-4 bg-white border border-slate-200 rounded-2xl focus:border-[#6366f1] focus:ring-4 focus:ring-[#6366f1]/5 transition-all outline-none font-medium text-slate-700 placeholder:text-slate-300 shadow-sm"
                                placeholder="••••••••"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="absolute right-5 top-1/2 -translate-y-1/2 text-slate-300 hover:text-slate-500 transition-colors"
                            >
                                {showPassword ? <EyeOff size={22} /> : <Eye size={22} />}
                            </button>
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-[#6366f1] text-white py-4.5 rounded-2xl font-bold text-lg hover:bg-[#4f46e5] shadow-lg shadow-indigo-100 transition-all active:scale-[0.98] disabled:opacity-50 mt-4 h-[60px]"
                    >
                        {loading ? 'Logging in...' : 'Login'}
                    </button>
                </form>

                <div className="mt-12 text-center">
                    <p className="text-slate-500 font-medium">
                        Don't have an account?{' '}
                        <Link to="/shop" className="text-[#6366f1] font-bold hover:text-[#4f46e5] transition-colors">Sign up</Link>
                    </p>
                </div>

                <div className="mt-8 pt-8 border-t border-slate-50 flex items-center justify-center space-x-6">
                    <a href="/admin" className="text-[10px] font-black text-slate-300 uppercase tracking-widest hover:text-slate-900 transition-colors flex items-center space-x-2">
                        <span>Admin Access</span>
                        <LogIn size={10} />
                    </a>
                </div>
            </div>
        </div>
    );
};

export default Login;
