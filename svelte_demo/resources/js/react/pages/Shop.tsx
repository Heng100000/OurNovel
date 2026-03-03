import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Plus, Minus, LayoutGrid, ShoppingCart, User as UserIcon, ArrowRight, BookOpen, Trash2, X, ChevronRight, Search, LogOut, LogIn, Filter } from 'lucide-react';

const linkify = (text: string) => {
    const urlRegex = /(https?:\/\/[^\s]+)/g;
    return text.split(urlRegex).map((part, index) => {
        if (part.match(urlRegex)) {
            return (
                <a
                    key={index}
                    href={part}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-emerald-600 hover:text-emerald-500 hover:underline break-all"
                    onClick={(e) => e.stopPropagation()}
                >
                    {part}
                </a>
            );
        }
        return <span key={index}>{part}</span>;
    });
};
import axios from 'axios';

// Types
interface Author {
    id: number;
    name: string;
    profile_image: string | null;
}

interface Book {
    id: number;
    title: string;
    price: number;
    cover_image: string | null;
    primary_image?: { image_url: string };
    author_name: string;
    description?: string;
    discounted_price?: number | null;
}


interface CartItem {
    id: number;
    book_id: number;
    book_title: string;
    book_author: string;
    book_image: string | null;
    unit_price: string;
    quantity: number;
}

const Shop: React.FC = () => {
    const navigate = useNavigate();
    const [user, setUser] = useState<any>(null);
    const [authors, setAuthors] = useState<Author[]>([]);
    const [books, setBooks] = useState<Book[]>([]);
    const [cart, setCart] = useState<CartItem[]>([]);
    const [selectedAuthorId, setSelectedAuthorId] = useState<number | null>(null);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [showCartMobile, setShowCartMobile] = useState(false);
    const [showSidebarMobile, setShowSidebarMobile] = useState(false);
    const [selectedBookForModal, setSelectedBookForModal] = useState<Book | null>(null);

    useEffect(() => {
        const token = localStorage.getItem('auth_token');
        if (token) {
            axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
            fetchUser();
        }

        fetchAuthors();
        fetchBooks();
        if (token) fetchCart();
    }, []);

    const fetchUser = async () => {
        const token = localStorage.getItem('auth_token');
        if (!token) {
            setUser(null);
            return;
        }

        try {
            const response = await axios.get('/api/user', {
                headers: { Authorization: `Bearer ${token}` }
            });
            const userData = response.data.data || response.data;
            setUser(userData);
            localStorage.setItem('user_data', JSON.stringify(userData));
        } catch (error) {
            setUser(null);
            localStorage.removeItem('auth_token');
            localStorage.removeItem('user_data');
        }
    };

    const handleLogout = async () => {
        const token = localStorage.getItem('auth_token');
        try {
            await axios.post('/api/logout', {}, {
                headers: { Authorization: `Bearer ${token}` }
            });
        } catch (error) {
            console.error('Logout failed:', error);
        } finally {
            setUser(null);
            localStorage.removeItem('auth_token');
            localStorage.removeItem('user_data');
            setCart([]);
            delete axios.defaults.headers.common['Authorization'];
            navigate('/shop');
        }
    };

    const fetchAuthors = async () => {
        try {
            const response = await axios.get('/api/authors');
            setAuthors(response.data.data || response.data);
        } catch (error) {
            console.error('Error fetching authors:', error);
        }
    };

    const fetchCart = async () => {
        const token = localStorage.getItem('auth_token');
        if (!token) return;

        try {
            const response = await axios.get('/api/cart', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setCart(response.data.data || Object.values(response.data));
        } catch (error) {
            console.error('Error fetching cart:', error);
        }
    };

    const fetchBooks = async (authorId: number | null = null) => {
        setLoading(true);
        try {
            const params: any = {};
            if (authorId) params.author_id = authorId;
            if (search) params.search = search;

            const response = await axios.get('/api/books', { params });
            setBooks(response.data.data || response.data);
        } catch (error) {
            console.error('Error fetching books:', error);
        } finally {
            setLoading(false);
        }
    };

    const addToCart = async (bookId: number) => {
        if (!user) {
            navigate('/shop/login');
            return;
        }

        const token = localStorage.getItem('auth_token');
        try {
            await axios.post('/api/cart', { book_id: bookId, quantity: 1 }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchCart();
        } catch (error) {
            console.error('Error adding to cart:', error);
        }
    };

    const updateCartQuantity = async (itemId: number, newQuantity: number) => {
        if (newQuantity < 1) return;

        const token = localStorage.getItem('auth_token');
        try {
            await axios.patch(`/api/cart/${itemId}`, { quantity: newQuantity }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchCart();
        } catch (error) {
            console.error('Error updating quantity:', error);
        }
    };

    const removeFromCart = async (itemId: number) => {
        const token = localStorage.getItem('auth_token');
        try {
            await axios.delete(`/api/cart/${itemId}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchCart();
        } catch (error) {
            console.error('Error removing item:', error);
        }
    };

    const handleAuthorSelect = (id: number | null) => {
        setSelectedAuthorId(id);
        fetchBooks(id);
    };

    const subtotal = cart.reduce((acc, item) => acc + (parseFloat(item.unit_price || '0') * item.quantity), 0);

    return (
        <div className="flex flex-col h-screen bg-[#fcfcfc] font-khmer text-slate-800 overflow-hidden">
            {/* Simple Friendly Header */}
            <header className="h-20 bg-white border-b border-slate-100 px-4 md:px-8 flex items-center justify-between flex-shrink-0 z-50">
                <div className="flex items-center space-x-3 md:space-x-4">
                    <button
                        onClick={() => setShowSidebarMobile(true)}
                        className="lg:hidden p-2 rounded-xl bg-slate-50 text-slate-500 hover:bg-slate-100 transition-colors"
                    >
                        <LayoutGrid size={22} />
                    </button>
                    <Link to="/shop" className="flex items-center">
                        <img src="/images/logo_full.png" alt="OurNovel Shop Logo" className="h-8 md:h-11 object-contain" />
                    </Link>
                </div>

                <div className="flex-1 max-w-xl mx-12 relative hidden md:block">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300" size={18} />
                    <input
                        type="text"
                        placeholder="Search for books or authors..."
                        className="w-full pl-11 pr-4 py-2.5 bg-slate-50 border-none rounded-xl focus:bg-white focus:ring-2 focus:ring-emerald-500/20 transition-all font-medium text-slate-600 outline-none placeholder:text-slate-300"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        onKeyUp={(e) => e.key === 'Enter' && fetchBooks(selectedAuthorId)}
                    />
                </div>

                <div className="flex items-center space-x-4">
                    <button
                        onClick={() => setShowCartMobile(true)}
                        className="lg:hidden p-3 rounded-xl bg-slate-50 text-slate-500 relative"
                    >
                        <ShoppingCart size={22} />
                        {cart.length > 0 && (
                            <span className="absolute -top-1 -right-1 w-5 h-5 bg-emerald-600 text-white text-[10px] font-bold rounded-full border-2 border-white flex items-center justify-center">
                                {cart.length}
                            </span>
                        )}
                    </button>

                    {user ? (
                        <div className="flex items-center space-x-3">
                            <div className="text-right hidden sm:block">
                                <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest leading-none">Welcome back</p>
                                <p className="text-[13px] font-bold text-slate-900 mt-1 leading-none">{user.name}</p>
                            </div>
                            <div className="group relative">
                                <button className="w-10 h-10 rounded-xl bg-slate-900 flex items-center justify-center text-white font-bold text-sm shadow-sm">
                                    {user.name.charAt(0).toUpperCase()}
                                </button>
                                <div className="absolute right-0 top-full mt-2 w-48 bg-white rounded-2xl shadow-xl border border-slate-100 p-1 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-[100]">
                                    <button
                                        onClick={handleLogout}
                                        className="w-full flex items-center space-x-2 px-4 py-2.5 rounded-xl text-slate-500 hover:bg-slate-50 hover:text-rose-500 transition-colors font-semibold text-xs uppercase"
                                    >
                                        <LogOut size={16} />
                                        <span>Sign Out</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    ) : (
                        <Link
                            to="/shop/login"
                            className="bg-emerald-600 text-white px-6 py-2.5 rounded-xl font-bold text-[13px] hover:bg-emerald-700 transition-all active:scale-95 shadow-md shadow-emerald-500/10"
                        >
                            Sign In
                        </Link>
                    )}
                </div>
            </header>

            <div className="flex flex-1 overflow-hidden">
                {/* Left Sidebar: Simple Author Nav */}
                <aside className="w-64 bg-white border-r border-slate-100 flex flex-col hidden lg:flex">
                    <div className="p-6">
                        <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em] mb-4">Categories</h3>
                        <button
                            onClick={() => handleAuthorSelect(null)}
                            className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all font-bold text-xs ${selectedAuthorId === null ? 'bg-emerald-50 text-emerald-700' : 'text-slate-500 hover:bg-slate-50'}`}
                        >
                            <LayoutGrid size={16} />
                            <span>All Collections</span>
                        </button>
                    </div>

                    <div className="flex-1 overflow-y-auto p-6 pt-0 no-scrollbar">
                        <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em] mb-4">Authors</h3>
                        <div className="space-y-1">
                            {authors.map(author => (
                                <button
                                    key={author.id}
                                    onClick={() => handleAuthorSelect(author.id)}
                                    className={`w-full flex items-center space-x-3 p-2 rounded-xl transition-all ${selectedAuthorId === author.id ? 'bg-emerald-50 text-emerald-700 font-bold' : 'text-slate-600 hover:bg-slate-50'}`}
                                >
                                    <div className={`w-9 h-9 rounded-lg flex-shrink-0 transition-all overflow-hidden ${selectedAuthorId === author.id ? 'ring-2 ring-emerald-200' : 'bg-slate-50'}`}>
                                        {author.profile_image ? (
                                            <img src={author.profile_image} alt={author.name} className="w-full h-full object-cover" />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center text-slate-300 font-bold text-[10px] uppercase">
                                                {author.name.charAt(0)}
                                            </div>
                                        )}
                                    </div>
                                    <span className="text-[12px] truncate">{author.name}</span>
                                </button>
                            ))}
                        </div>
                    </div>
                </aside>

                {/* Center: Clean Product Grid */}
                <main className="flex-1 bg-slate-50/50 overflow-y-auto no-scrollbar p-8">
                    <div className="max-w-6xl mx-auto">
                        <div className="flex items-center justify-between mb-8">
                            <h2 className="text-2xl font-bold text-slate-900">
                                {selectedAuthorId ? authors.find(a => a.id === selectedAuthorId)?.name : 'Book Catalog'}
                            </h2>
                            <div className="flex items-center space-x-2 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                                <span>{books.length} Books found</span>
                            </div>
                        </div>

                        {loading ? (
                            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 md:gap-6">
                                {[1, 2, 3, 4, 5, 6, 7, 8].map(i => (
                                    <div key={i} className="bg-white rounded-2xl p-4 border border-slate-100 space-y-4 animate-pulse">
                                        <div className="aspect-[3/4] bg-slate-100 rounded-xl w-full"></div>
                                        <div className="h-3 bg-slate-100 rounded-full w-3/4"></div>
                                        <div className="h-3 bg-slate-100 rounded-full w-1/2"></div>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6 mb-20 px-2 lg:px-0">
                                {books.map(book => (
                                    <div
                                        key={book.id}
                                        onClick={() => setSelectedBookForModal(book)}
                                        className="bg-white rounded-2xl p-4 border border-slate-100 hover:border-emerald-200 hover:shadow-lg transition-all flex flex-col group cursor-pointer"
                                    >
                                        <div className="aspect-[3/4] rounded-xl overflow-hidden mb-4 bg-slate-50 relative">
                                            {(book.primary_image?.image_url || book.cover_image) ? (
                                                <img
                                                    src={(book.primary_image?.image_url || book.cover_image || '').startsWith('http') ? (book.primary_image?.image_url || book.cover_image) : `/storage/${book.primary_image?.image_url || book.cover_image}`}
                                                    alt={book.title}
                                                    className="w-full h-full object-cover transition-transform group-hover:scale-105 duration-300"
                                                />
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center text-slate-300">
                                                    <BookOpen size={32} className="opacity-20" />
                                                </div>
                                            )}
                                        </div>
                                        <div className="flex-1 flex flex-col">
                                            <h4 className="font-bold text-slate-800 line-clamp-2 text-sm leading-snug mb-1">{book.title}</h4>
                                            <p className="text-[10px] font-semibold text-slate-400 mb-4 tracking-wide">by {book.author_name}</p>

                                            <div className="mt-auto flex items-center justify-between pt-2">
                                                <div className="flex flex-col">
                                                    {book.discounted_price ? (
                                                        <>
                                                            <span className="text-[10px] font-bold text-slate-400 line-through">${book.price}</span>
                                                            <span className="text-[15px] font-bold text-rose-500">${book.discounted_price}</span>
                                                        </>
                                                    ) : (
                                                        <span className="text-[15px] font-bold text-slate-900">${book.price}</span>
                                                    )}
                                                </div>
                                                <button
                                                    onClick={(e) => { e.stopPropagation(); addToCart(book.id); }}
                                                    className="w-9 h-9 bg-emerald-600 text-white rounded-lg flex items-center justify-center hover:bg-emerald-700 transition-colors shadow-sm shadow-emerald-500/10 active:scale-90"
                                                >
                                                    <Plus size={18} />
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </main>

                {/* Right Sidebar: Simple Cart */}
                <aside className="w-[350px] bg-white border-l border-slate-100 flex flex-col hidden lg:flex">
                    <div className="p-6 border-b border-slate-50 flex items-center space-x-3">
                        <ShoppingCart size={20} className="text-emerald-600" />
                        <h3 className="font-bold text-slate-900 uppercase text-xs tracking-wider">Your Order</h3>
                        <span className="bg-slate-100 text-slate-500 px-2 py-0.5 rounded text-[10px] font-bold ml-auto">{cart.length}</span>
                    </div>

                    <div className="flex-1 overflow-y-auto p-6 space-y-6 no-scrollbar">
                        {cart.map(item => (
                            <div key={item.id} className="flex space-x-4">
                                <div className="w-14 h-18 bg-slate-50 rounded-lg overflow-hidden flex-shrink-0 border border-slate-100">
                                    {item.book_image && <img src={item.book_image} alt={item.book_title} className="w-full h-full object-cover" />}
                                </div>
                                <div className="flex-1 min-w-0">
                                    <h4 className="font-bold text-slate-800 truncate text-[13px] mb-0.5">{item.book_title}</h4>
                                    <p className="text-[10px] font-semibold text-slate-400 mb-2">{item.book_author}</p>

                                    <div className="flex items-center justify-between">
                                        <span className="font-bold text-slate-900 text-sm">${item.unit_price}</span>
                                        <div className="flex items-center space-x-1">
                                            <button
                                                onClick={() => updateCartQuantity(item.id, item.quantity - 1)}
                                                className="w-6 h-6 flex items-center justify-center text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded transition-all"
                                                disabled={item.quantity <= 1}
                                            >
                                                <Minus size={12} />
                                            </button>
                                            <span className="w-6 text-center text-xs font-bold text-slate-600">{item.quantity}</span>
                                            <button
                                                onClick={() => updateCartQuantity(item.id, item.quantity + 1)}
                                                className="w-6 h-6 flex items-center justify-center text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded transition-all"
                                            >
                                                <Plus size={12} />
                                            </button>
                                            <button
                                                onClick={() => removeFromCart(item.id)}
                                                className="ml-2 w-6 h-6 flex items-center justify-center text-slate-300 hover:text-rose-500 transition-colors"
                                            >
                                                <Trash2 size={12} />
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ))}
                        {cart.length === 0 && (
                            <div className="h-full flex flex-col items-center justify-center py-20 text-center text-slate-300">
                                <ShoppingCart size={32} className="mb-3 opacity-20" />
                                <p className="text-[10px] font-bold uppercase tracking-wider">Empty Folder</p>
                            </div>
                        )}
                    </div>

                    <div className="p-6 bg-slate-50 border-t border-slate-100 space-y-4">
                        <div className="flex justify-between items-center">
                            <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Total</span>
                            <span className="text-2xl font-bold text-slate-900">${subtotal.toFixed(2)}</span>
                        </div>
                        <button
                            onClick={() => navigate('/shop/checkout')}
                            className="w-full bg-emerald-600 hover:bg-emerald-700 disabled:bg-slate-200 text-white py-3.5 rounded-xl font-bold text-[14px] shadow-lg shadow-emerald-500/10 active:scale-[0.98] transition-all"
                            disabled={cart.length === 0}
                        >
                            Finish Order
                        </button>
                    </div>
                </aside>
            </div>

            {/* Simple Mobile Cart */}
            {showCartMobile && (
                <div className="fixed inset-0 z-[100] lg:hidden">
                    <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => setShowCartMobile(false)}></div>
                    <div className="absolute right-0 top-0 bottom-0 w-[85%] max-w-sm bg-white flex flex-col shadow-2xl animate-in slide-in-from-right duration-300">
                        <div className="p-6 border-b border-slate-50 flex items-center justify-between">
                            <h2 className="text-lg font-bold text-slate-900">Your Cart</h2>
                            <button onClick={() => setShowCartMobile(false)} className="w-10 h-10 rounded-xl bg-slate-50 text-slate-400 flex items-center justify-center">
                                <X size={22} />
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto p-6 space-y-6 no-scrollbar">
                            {cart.map(item => (
                                <div key={item.id} className="flex items-center space-x-4">
                                    <div className="w-16 h-20 bg-slate-50 rounded-xl overflow-hidden border border-slate-100 flex-shrink-0">
                                        {item.book_image && <img src={item.book_image} alt={item.book_title} className="w-full h-full object-cover" />}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <h4 className="font-bold text-slate-800 text-sm truncate">{item.book_title}</h4>
                                        <div className="flex items-center justify-between mt-2">
                                            <span className="font-bold text-slate-900">${item.unit_price}</span>
                                            <div className="flex items-center space-x-1">
                                                <button
                                                    onClick={() => updateCartQuantity(item.id, item.quantity - 1)}
                                                    className="w-6 h-6 flex items-center justify-center text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded transition-all"
                                                    disabled={item.quantity <= 1}
                                                >
                                                    <Minus size={12} />
                                                </button>
                                                <span className="w-6 text-center text-xs font-bold text-slate-600">{item.quantity}</span>
                                                <button
                                                    onClick={() => updateCartQuantity(item.id, item.quantity + 1)}
                                                    className="w-6 h-6 flex items-center justify-center text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded transition-all"
                                                >
                                                    <Plus size={12} />
                                                </button>
                                                <button
                                                    onClick={() => removeFromCart(item.id)}
                                                    className="ml-2 w-6 h-6 flex items-center justify-center text-slate-300 hover:text-rose-500 transition-colors"
                                                >
                                                    <Trash2 size={12} />
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                        <div className="p-8 bg-slate-50 border-t border-slate-100">
                            <div className="flex justify-between items-center mb-6">
                                <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">Total</span>
                                <span className="text-2xl font-bold text-slate-900">${subtotal.toFixed(2)}</span>
                            </div>
                            <button onClick={() => navigate('/shop/checkout')} className="w-full bg-emerald-600 text-white py-4 rounded-xl font-bold text-sm shadow-lg shadow-emerald-500/10 active:scale-[0.98]">Checkout</button>
                        </div>
                    </div>
                </div>
            )}

            {/* Simple Mobile Sidebar */}
            {showSidebarMobile && (
                <div className="fixed inset-0 z-[100] lg:hidden">
                    <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => setShowSidebarMobile(false)}></div>
                    <div className="absolute left-0 top-0 bottom-0 w-[80%] max-w-[280px] bg-white flex flex-col shadow-2xl animate-in slide-in-from-left duration-300">
                        <div className="p-6 flex items-center justify-between border-b border-slate-50">
                            <h2 className="text-lg font-bold text-slate-900">Menu</h2>
                            <button onClick={() => setShowSidebarMobile(false)} className="w-10 h-10 rounded-xl bg-slate-50 text-slate-400 flex items-center justify-center">
                                <X size={22} />
                            </button>
                        </div>
                        <div className="p-6 border-b border-slate-50">
                            <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em] mb-4">Categories</h3>
                            <button
                                onClick={() => { handleAuthorSelect(null); setShowSidebarMobile(false); }}
                                className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition-all font-bold text-xs ${selectedAuthorId === null ? 'bg-emerald-50 text-emerald-700' : 'text-slate-500 hover:bg-slate-50'}`}
                            >
                                <LayoutGrid size={16} />
                                <span>All Collections</span>
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto p-6 pt-6 no-scrollbar">
                            <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em] mb-4">Authors</h3>
                            <div className="space-y-1">
                                {authors.map(author => (
                                    <button
                                        key={author.id}
                                        onClick={() => { handleAuthorSelect(author.id); setShowSidebarMobile(false); }}
                                        className={`w-full flex items-center space-x-3 p-2 rounded-xl transition-all ${selectedAuthorId === author.id ? 'bg-emerald-50 text-emerald-700 font-bold' : 'text-slate-600 hover:bg-slate-50'}`}
                                    >
                                        <div className={`w-9 h-9 rounded-lg flex-shrink-0 transition-all overflow-hidden ${selectedAuthorId === author.id ? 'ring-2 ring-emerald-200' : 'bg-slate-50'}`}>
                                            {author.profile_image ? (
                                                <img src={author.profile_image} alt={author.name} className="w-full h-full object-cover" />
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center text-slate-300 font-bold text-[10px] uppercase">
                                                    {author.name.charAt(0)}
                                                </div>
                                            )}
                                        </div>
                                        <span className="text-[12px] truncate">{author.name}</span>
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Book Detail Modal */}
            {selectedBookForModal && (
                <div className="fixed inset-0 z-[110] flex items-center justify-center p-4">
                    <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => setSelectedBookForModal(null)}></div>
                    <div className="relative w-full max-w-3xl bg-white rounded-3xl shadow-2xl animate-in zoom-in-95 duration-200 overflow-hidden flex flex-col max-h-[90vh]">
                        <div className="absolute top-4 right-4 z-10">
                            <button onClick={() => setSelectedBookForModal(null)} className="w-10 h-10 rounded-full bg-white/80 backdrop-blur text-slate-400 hover:text-slate-900 hover:bg-white shadow-sm flex items-center justify-center transition-all">
                                <X size={20} />
                            </button>
                        </div>
                        <div className="flex flex-col md:flex-row h-full overflow-y-auto no-scrollbar">
                            <div className="w-full md:w-[45%] bg-slate-50 p-6 md:p-8 flex items-center justify-center flex-shrink-0">
                                <div className="aspect-[3/4] w-full max-w-[280px] rounded-2xl overflow-hidden shadow-md">
                                    {(selectedBookForModal.primary_image?.image_url || selectedBookForModal.cover_image) ? (
                                        <img
                                            src={(selectedBookForModal.primary_image?.image_url || selectedBookForModal.cover_image || '').startsWith('http') ? (selectedBookForModal.primary_image?.image_url || selectedBookForModal.cover_image) : `/storage/${selectedBookForModal.primary_image?.image_url || selectedBookForModal.cover_image}`}
                                            alt={selectedBookForModal.title}
                                            className="w-full h-full object-cover"
                                        />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center bg-slate-100 text-slate-300">
                                            <BookOpen size={48} className="opacity-20" />
                                        </div>
                                    )}
                                </div>
                            </div>
                            <div className="flex-1 p-6 md:p-8 flex flex-col">
                                <div className="mb-2">
                                    <span className="inline-block px-3 py-1 bg-emerald-50 text-emerald-700 text-[10px] font-bold uppercase tracking-widest rounded-full mb-3">
                                        Book Detail
                                    </span>
                                </div>
                                <h2 className="text-2xl md:text-3xl font-bold text-slate-900 leading-tight mb-2">
                                    {selectedBookForModal.title}
                                </h2>
                                <p className="text-sm font-bold text-slate-400 mb-6">by {selectedBookForModal.author_name}</p>

                                <div className="prose prose-sm prose-slate mb-8 flex-1">
                                    <h3 className="text-xs font-bold uppercase tracking-wider text-slate-900 mb-2">Description</h3>
                                    <p className="text-slate-600 leading-relaxed whitespace-pre-wrap">
                                        {selectedBookForModal.description ? linkify(selectedBookForModal.description) : "No description available for this book yet. Please check back later for more details."}
                                    </p>
                                </div>

                                <div className="mt-auto pt-6 border-t border-slate-100 flex items-center justify-between">
                                    <div className="flex flex-col">
                                        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Price</span>
                                        {selectedBookForModal.discounted_price ? (
                                            <div className="space-x-2 flex items-baseline">
                                                <span className="text-2xl font-bold text-rose-500">${selectedBookForModal.discounted_price}</span>
                                                <span className="text-sm font-bold text-slate-400 line-through">${selectedBookForModal.price}</span>
                                            </div>
                                        ) : (
                                            <span className="text-2xl font-bold text-emerald-600">${selectedBookForModal.price}</span>
                                        )}
                                    </div>
                                    <button
                                        onClick={() => { addToCart(selectedBookForModal.id); setSelectedBookForModal(null); }}
                                        className="bg-emerald-600 hover:bg-emerald-700 text-white px-8 py-3.5 rounded-xl font-bold text-sm shadow-md shadow-emerald-500/20 active:scale-95 transition-all flex items-center space-x-2"
                                    >
                                        <ShoppingCart size={18} />
                                        <span>Add to Cart</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            <style>{`
                @import url('https://fonts.googleapis.com/css2?family=Kantumruy+Pro:ital,wght@0,100..700;1,100..700&display=swap');
                .font-khmer { font-family: 'Kantumruy Pro', sans-serif; }
                .no-scrollbar::-webkit-scrollbar { display: none; }
                .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
            `}</style>
        </div>
    );
};

export default Shop;
