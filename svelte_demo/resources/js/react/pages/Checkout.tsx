import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import axios from 'axios';
import { CheckCircle2, MapPin, Package, ShieldCheck, ShoppingCart, User, ArrowLeft, Loader2, QrCode, X, ChevronLeft, Tag, Truck, Trash2 } from 'lucide-react';

interface CartItem {
    id: number;
    book_id: number;
    book_title: string;
    book_author: string;
    book_image: string | null;
    unit_price: string;
    quantity: number;
}

interface UserAddress {
    id: number;
    title: string;
    address: string;
    city_province: string;
    phone: string;
    is_default: boolean;
}

interface ShippingRate {
    location_name: string;
    fee: string;
}

interface DeliveryCompany {
    id: number;
    name: string;
    estimated_days: string;
    logo_path?: string;
    logo_url?: string;
    shipping_rates?: ShippingRate[];
}

interface AppliedCoupon {
    id: number;
    code: string;
    discount_amount: number;
    type: string;
}

const Checkout: React.FC = () => {
    const navigate = useNavigate();
    const [user, setUser] = useState<any>(null);
    const [cart, setCart] = useState<CartItem[]>([]);
    const [addresses, setAddresses] = useState<UserAddress[]>([]);
    const [deliveryCompanies, setDeliveryCompanies] = useState<DeliveryCompany[]>([]);

    const [selectedAddressId, setSelectedAddressId] = useState<number | null>(null);
    const [selectedCompanyId, setSelectedCompanyId] = useState<number | null>(null);

    const [couponCode, setCouponCode] = useState('');
    const [appliedCoupon, setAppliedCoupon] = useState<AppliedCoupon | null>(null);
    const [applyingCoupon, setApplyingCoupon] = useState(false);
    const [couponError, setCouponError] = useState('');

    const [loading, setLoading] = useState(true);

    const [showAddAddressForm, setShowAddAddressForm] = useState(false);
    const [newAddress, setNewAddress] = useState({
        title: '',
        address: '',
        city_province: '',
        phone: ''
    });

    const [khqrData, setKhqrData] = useState<any>(null);
    const [khqrModalOpen, setKhqrModalOpen] = useState(false);
    const [paymentSuccess, setPaymentSuccess] = useState(false);

    useEffect(() => {
        const token = localStorage.getItem('auth_token');
        if (!token) {
            navigate('/shop/login');
            return;
        }

        axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
        const userData = localStorage.getItem('user_data');
        if (userData) {
            setUser(JSON.parse(userData));
        }

        fetchData();
    }, [navigate]);

    useEffect(() => {
        let interval: NodeJS.Timeout;
        if (khqrModalOpen && khqrData && !paymentSuccess) {
            interval = setInterval(async () => {
                try {
                    const res = await axios.get(`/api/payments/${khqrData.id}/check-khqr`);
                    if (res.data.paid) {
                        setPaymentSuccess(true);
                        setKhqrModalOpen(false); // Close modal on success
                        setCart([]); // Optimistically clear cart
                    }
                } catch (err) {
                    console.error('Polling error', err);
                }
            }, 3000);
        }
        return () => clearInterval(interval);
    }, [khqrModalOpen, khqrData, paymentSuccess]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const [cartRes, addressesRes, companiesRes] = await Promise.all([
                axios.get('/api/cart'),
                axios.get('/api/user/addresses'),
                axios.get('/api/delivery-companies')
            ]);

            setCart(cartRes.data.data || Object.values(cartRes.data));

            const fetchedAddresses = addressesRes.data.data || addressesRes.data;
            setAddresses(fetchedAddresses);
            if (fetchedAddresses.length > 0) {
                const defaultAddr = fetchedAddresses.find((a: UserAddress) => a.is_default);
                setSelectedAddressId(defaultAddr ? defaultAddr.id : fetchedAddresses[0].id);
            }

            const fetchedCompanies = companiesRes.data.data || companiesRes.data;
            setDeliveryCompanies(fetchedCompanies);
            if (fetchedCompanies.length > 0) {
                setSelectedCompanyId(fetchedCompanies[0].id);
            }

        } catch (error) {
            console.error('Error fetching checkout data:', error);
        } finally {
            setLoading(false);
        }
    };

    const subtotal = cart.reduce((acc, item) => acc + (parseFloat(item.unit_price || '0') * item.quantity), 0);

    // Fetch shipping fee from the selected company's first shipping rate, matching backend OrderController logic
    const selectedCompany = deliveryCompanies.find(c => c.id === selectedCompanyId);
    const shippingFee = selectedCompany?.shipping_rates && selectedCompany.shipping_rates.length > 0
        ? parseFloat(selectedCompany.shipping_rates[0].fee || '0')
        : 0;

    const discountAmount = appliedCoupon ? appliedCoupon.discount_amount : 0;
    const total = Math.max(0, subtotal - discountAmount) + shippingFee;

    const handleApplyCoupon = async () => {
        setCouponError('');
        if (!couponCode.trim()) {
            setCouponError('Please enter a coupon code.');
            return;
        }

        setApplyingCoupon(true);
        try {
            const res = await axios.post('/api/coupons/apply', {
                code: couponCode,
                subtotal: subtotal
            });
            setAppliedCoupon(res.data);
            setCouponCode('');
        } catch (error: any) {
            setCouponError(error.response?.data?.message || 'Invalid coupon code.');
            setAppliedCoupon(null);
        } finally {
            setApplyingCoupon(false);
        }
    };

    const handleRemoveCoupon = () => {
        setAppliedCoupon(null);
        setCouponCode('');
        setCouponError('');
    };

    const handlePlaceOrder = async () => {
        if (!selectedAddressId || !selectedCompanyId) {
            alert('Please select an address and delivery company.');
            return;
        }

        try {
            // 1. Create Order
            const orderRes = await axios.post('/api/orders', {
                delivery_method: 'delivery',
                address_id: selectedAddressId,
                delivery_company_id: selectedCompanyId,
                status: 'Pending',
                coupon_code: appliedCoupon ? appliedCoupon.code : null,
            });

            const order = orderRes.data;

            // 2. Initialize Payment (KHQR)
            const paymentRes = await axios.post('/api/payments', {
                order_id: order.id,
                method: 'bakong' // Enforce Bakong KHQR
            });

            const payment = paymentRes.data.data || paymentRes.data;

            console.log('Payment created:', payment);
            if (payment.qr_image_url) {
                setKhqrData(payment);
                setKhqrModalOpen(true);
            } else {
                alert('Order placed successfully, but KHQR could not be generated.');
                navigate('/shop');
            }

        } catch (error: any) {
            console.error('Failed to place order:', error);
            alert(error.response?.data?.message || 'Failed to place order');
        }
    };

    const handleAddAddress = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const res = await axios.post('/api/user/addresses', newAddress);
            const addedAddress = res.data.data || res.data;
            setAddresses([addedAddress, ...addresses]);
            setSelectedAddressId(addedAddress.id);
            setShowAddAddressForm(false);
            setNewAddress({ title: '', address: '', city_province: '', phone: '' });
        } catch (err: any) {
            console.error('Failed to add address', err);
            alert('Failed to add address. Please fill all fields.');
        }
    };

    const handleDeleteAddress = async (e: React.MouseEvent, id: number) => {
        e.stopPropagation();
        if (!confirm('Are you sure you want to delete this address?')) return;

        try {
            await axios.delete(`/api/user/addresses/${id}`);
            const newAddresses = addresses.filter(a => a.id !== id);
            setAddresses(newAddresses);
            if (selectedAddressId === id) {
                setSelectedAddressId(newAddresses.length > 0 ? newAddresses[0].id : null);
            }
        } catch (err) {
            console.error('Failed to delete address', err);
            alert('Failed to delete address.');
        }
    };

    // Auto-redirect after payment success
    useEffect(() => {
        if (paymentSuccess) {
            const timer = setTimeout(() => {
                navigate('/shop');
            }, 5000);
            return () => clearTimeout(timer);
        }
    }, [paymentSuccess, navigate]);

    if (paymentSuccess) {
        return (
            <div className="min-h-screen flex flex-col items-center justify-center bg-[#fcfcfc] font-khmer">
                <div className="w-24 h-24 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mb-6 animate-bounce">
                    <CheckCircle2 size={48} />
                </div>
                <h1 className="text-3xl font-bold text-slate-900 mb-2">Payment Successful!</h1>
                <p className="text-slate-500 mb-8 max-w-sm text-center">Your order has been placed and payment confirmed. You will be redirected shortly.</p>
                <Link to="/shop" className="bg-emerald-600 hover:bg-emerald-700 text-white px-8 py-3 rounded-xl font-bold transition-all shadow-lg shadow-emerald-500/20 active:scale-95">
                    Return to Shop Now
                </Link>
            </div>
        );
    }

    if (loading) {
        return <div className="min-h-screen flex items-center justify-center bg-[#fcfcfc]">Loading checkout...</div>;
    }

    if (cart.length === 0) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-[#fcfcfc] flex-col space-y-4">
                <p className="text-xl font-bold text-slate-400">Your cart is empty.</p>
                <Link to="/shop" className="text-emerald-600 font-bold hover:underline">Return to Shop</Link>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-[#fcfcfc] font-khmer text-slate-800 pb-20">
            {/* Header */}
            <header className="h-20 bg-white border-b border-slate-100 px-4 md:px-8 flex items-center justify-between sticky top-0 z-40">
                <div className="flex items-center space-x-4">
                    <Link to="/shop" className="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center text-slate-500 hover:bg-slate-100 transition-colors">
                        <ChevronLeft size={20} />
                    </Link>
                    <h1 className="text-xl font-bold tracking-tight text-slate-900 leading-none">Checkout</h1>
                </div>
                {user && (
                    <div className="flex items-center space-x-3">
                        <div className="text-right hidden sm:block">
                            <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest leading-none">{user.email}</p>
                            <p className="text-[13px] font-bold text-slate-900 mt-1 leading-none">{user.name}</p>
                        </div>
                        <div className="w-10 h-10 rounded-xl bg-emerald-600 flex items-center justify-center text-white font-bold text-sm shadow-sm">
                            <User size={18} />
                        </div>
                    </div>
                )}
            </header>

            <div className="w-full max-w-[1400px] mx-auto px-4 md:px-8 py-8 flex flex-col lg:flex-row gap-8">

                {/* Main Content */}
                <div className="flex-1 space-y-8">

                    {/* Address Selection */}
                    <div className="bg-white rounded-3xl p-6 md:p-8 border border-slate-100 shadow-sm relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-50 rounded-bl-full -z-0 opacity-50"></div>
                        <div className="flex items-center justify-between mb-6 relative z-10">
                            <h2 className="text-lg font-bold text-slate-900 flex items-center space-x-2">
                                <MapPin className="text-emerald-500" size={20} />
                                <span>Shipping Address</span>
                            </h2>
                            {!showAddAddressForm && (
                                <button
                                    onClick={() => setShowAddAddressForm(true)}
                                    className="text-emerald-600 font-bold text-sm hover:underline"
                                >
                                    + Add New
                                </button>
                            )}
                        </div>

                        {showAddAddressForm ? (
                            <form onSubmit={handleAddAddress} className="relative z-10 space-y-4 bg-slate-50 p-6 rounded-2xl border border-slate-100">
                                <div>
                                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-widest mb-1">Title (e.g. Home, Office)</label>
                                    <input required type="text" value={newAddress.title} onChange={e => setNewAddress({ ...newAddress, title: e.target.value })} className="w-full p-3 rounded-xl border border-slate-200 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all" />
                                </div>
                                <div>
                                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-widest mb-1">Phone Number</label>
                                    <input required type="text" value={newAddress.phone} onChange={e => setNewAddress({ ...newAddress, phone: e.target.value })} className="w-full p-3 rounded-xl border border-slate-200 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all" />
                                </div>
                                <div>
                                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-widest mb-1">City / Province</label>
                                    <input type="text" value={newAddress.city_province} onChange={e => setNewAddress({ ...newAddress, city_province: e.target.value })} className="w-full p-3 rounded-xl border border-slate-200 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all" />
                                </div>
                                <div>
                                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-widest mb-1">Full Address (Street, House No, etc.)</label>
                                    <textarea required rows={3} value={newAddress.address} onChange={e => setNewAddress({ ...newAddress, address: e.target.value })} className="w-full p-3 rounded-xl border border-slate-200 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all"></textarea>
                                </div>
                                <div className="flex space-x-3 pt-2">
                                    <button type="submit" className="bg-emerald-600 text-white px-6 py-2.5 rounded-xl font-bold hover:bg-emerald-700 transition-colors">Save Address</button>
                                    <button type="button" onClick={() => setShowAddAddressForm(false)} className="text-slate-500 font-bold px-6 py-2.5 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors">Cancel</button>
                                </div>
                            </form>
                        ) : addresses.length === 0 ? (
                            <div className="p-4 bg-amber-50 rounded-xl text-amber-700 text-sm font-bold border border-amber-100 flex flex-col items-center justify-center py-8">
                                <MapPin size={32} className="mb-2 opacity-50" />
                                <p>You don't have a shipping address.</p>
                                <button onClick={() => setShowAddAddressForm(true)} className="mt-4 bg-amber-600 text-white px-6 py-2 rounded-lg font-bold hover:bg-amber-700 transition-colors">Add Address Now</button>
                            </div>
                        ) : (
                            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 relative z-10">
                                {addresses.map(addr => (
                                    <div
                                        key={addr.id}
                                        onClick={() => setSelectedAddressId(addr.id)}
                                        className={`p-5 rounded-2xl border-2 transition-all cursor-pointer relative group ${selectedAddressId === addr.id ? 'border-emerald-500 bg-emerald-50/30 shadow-md shadow-emerald-500/10' : 'border-slate-100 hover:border-emerald-200 bg-white'}`}
                                    >
                                        <button
                                            onClick={(e) => handleDeleteAddress(e, addr.id)}
                                            className="absolute top-3 right-3 text-slate-300 hover:text-red-500 p-1.5 rounded-lg hover:bg-red-50 opacity-0 group-hover:opacity-100 transition-all"
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                        <div className="flex items-start justify-between mb-2 pr-6">
                                            <span className="font-bold text-slate-900 text-sm flex items-center space-x-2">
                                                <span>{addr.title}</span>
                                                {addr.is_default && <span className="text-[9px] bg-slate-100 text-slate-500 px-2 py-0.5 rounded-full uppercase tracking-widest">Default</span>}
                                            </span>
                                            {selectedAddressId === addr.id && <CheckCircle2 size={18} className="text-emerald-500 flex-shrink-0" />}
                                        </div>
                                        <p className="text-xs text-slate-500 leading-relaxed mb-4 min-h-[40px]">{addr.address}</p>
                                        <div className="flex justify-between items-center pt-3 border-t border-slate-100">
                                            <span className="text-xs font-bold text-slate-400 capitalize">{addr.city_province || 'Not specified'}</span>
                                            <span className="text-xs font-bold text-slate-700">{addr.phone}</span>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Delivery Company */}
                    <div className="bg-white rounded-3xl p-6 md:p-8 border border-slate-100 shadow-sm">
                        <h2 className="text-lg font-bold text-slate-900 mb-6 flex items-center space-x-2">
                            <Truck className="text-blue-500" size={20} />
                            <span>Delivery Partner</span>
                        </h2>

                        <div className="space-y-3">
                            {deliveryCompanies.map(company => (
                                <div
                                    key={company.id}
                                    onClick={() => setSelectedCompanyId(company.id)}
                                    className={`flex items-center p-4 rounded-2xl border-2 transition-all cursor-pointer ${selectedCompanyId === company.id ? 'border-blue-500 bg-blue-50/30 shadow-md shadow-blue-500/10' : 'border-slate-100 hover:border-blue-200 bg-white'}`}
                                >
                                    <div className="w-12 h-12 bg-slate-50 rounded-xl p-2 mr-4 border border-slate-100 flex items-center justify-center">
                                        {company.logo_url ? (
                                            <img src={company.logo_url} alt={company.name} className="max-w-full max-h-full object-contain" />
                                        ) : (
                                            <span className="text-[10px] font-bold text-slate-400">Logo</span>
                                        )}
                                    </div>
                                    <div className="flex-1">
                                        <h3 className="font-bold text-slate-900 text-sm mb-1">{company.name}</h3>
                                        <p className="text-xs text-slate-400">
                                            {company.shipping_rates && company.shipping_rates.length > 0
                                                ? company.shipping_rates[0].location_name
                                                : 'Standard Delivery'}
                                        </p>
                                    </div>
                                    <div className="text-right flex flex-col items-end">
                                        <span className="font-bold text-slate-900">
                                            ${company.shipping_rates && company.shipping_rates.length > 0 ? parseFloat(company.shipping_rates[0].fee).toFixed(2) : '0.00'}
                                        </span>
                                        {selectedCompanyId === company.id && <CheckCircle2 size={16} className="text-blue-500 mt-2" />}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                </div>

                {/* Sidebar Summary */}
                <div className="w-full lg:w-[380px]">
                    <div className="bg-white rounded-3xl p-6 md:p-8 border border-slate-100 shadow-sm sticky top-28">
                        <h2 className="text-lg font-bold text-slate-900 mb-6">Order Summary</h2>

                        <div className="space-y-4 mb-6 max-h-[30vh] overflow-y-auto pr-2 no-scrollbar">
                            {cart.map(item => (
                                <div key={item.id} className="flex items-start space-x-3">
                                    <div className="w-12 h-16 bg-slate-50 rounded-lg overflow-hidden border border-slate-100 flex-shrink-0">
                                        {item.book_image && <img src={item.book_image} alt={item.book_title} className="w-full h-full object-cover" />}
                                    </div>
                                    <div className="flex-1 min-w-0 pt-1">
                                        <h4 className="font-bold text-slate-800 text-[13px] truncate">{item.book_title}</h4>
                                        <p className="text-[10px] font-medium text-slate-400 mb-1">Qty: {item.quantity}</p>
                                        <span className="font-bold text-slate-900 text-xs">${(item.quantity * parseFloat(item.unit_price)).toFixed(2)}</span>
                                    </div>
                                </div>
                            ))}
                        </div>

                        <div className="border-t border-slate-100 pt-6 space-y-3 mb-6">

                            {/* Promo Code Input Section */}
                            <div className="mb-4">
                                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2 block">Promo Code</label>
                                {appliedCoupon ? (
                                    <div className="flex items-center justify-between bg-emerald-50 border border-emerald-100 rounded-xl p-3">
                                        <div className="flex items-center space-x-2 text-emerald-700">
                                            <Tag size={16} />
                                            <span className="font-bold text-sm tracking-wide">{appliedCoupon.code}</span>
                                        </div>
                                        <button onClick={handleRemoveCoupon} className="text-emerald-500 hover:text-emerald-700 transition">
                                            <X size={16} />
                                        </button>
                                    </div>
                                ) : (
                                    <div className="flex items-start space-x-2">
                                        <div className="flex-1">
                                            <input
                                                type="text"
                                                value={couponCode}
                                                onChange={(e) => setCouponCode(e.target.value)}
                                                placeholder="Enter code"
                                                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-sm font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                                            />
                                            {couponError && <p className="text-xs text-rose-500 font-medium mt-1 pl-1">{couponError}</p>}
                                        </div>
                                        <button
                                            onClick={handleApplyCoupon}
                                            disabled={applyingCoupon || !couponCode.trim()}
                                            className="bg-slate-900 hover:bg-black disabled:bg-slate-300 text-white px-4 py-3 rounded-xl font-bold text-sm transition-colors flexitems-center h-[46px]"
                                        >
                                            {applyingCoupon ? <Loader2 size={16} className="animate-spin" /> : 'Apply'}
                                        </button>
                                    </div>
                                )}
                            </div>

                            <div className="flex justify-between items-center text-sm pt-2">
                                <span className="text-slate-500 font-medium">Subtotal</span>
                                <span className="font-bold text-slate-900">${subtotal.toFixed(2)}</span>
                            </div>
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-slate-500 font-medium">Shipping Fee</span>
                                <span className="font-bold text-slate-900">${shippingFee.toFixed(2)}</span>
                            </div>
                            {appliedCoupon && (
                                <div className="flex justify-between items-center text-sm">
                                    <span className="text-emerald-500 font-bold">Discount ({appliedCoupon.code})</span>
                                    <span className="font-bold text-emerald-500">-${discountAmount.toFixed(2)}</span>
                                </div>
                            )}
                        </div>

                        <div className="border-t border-slate-100 pt-6 mb-8">
                            <div className="flex justify-between items-end">
                                <span className="text-sm font-bold text-slate-400 uppercase tracking-widest">Total Pay</span>
                                <span className="text-3xl font-bold text-slate-900">${total.toFixed(2)}</span>
                            </div>
                            <p className="text-[10px] text-right text-slate-400 font-medium mt-1">Includes all applicable taxes</p>
                        </div>

                        <button
                            onClick={handlePlaceOrder}
                            disabled={!selectedAddressId || !selectedCompanyId || cart.length === 0}
                            className="w-full bg-slate-900 hover:bg-black disabled:bg-slate-200 text-white py-4 rounded-2xl font-bold text-sm shadow-xl shadow-slate-900/10 active:scale-[0.98] transition-all flex items-center justify-center space-x-2"
                        >
                            <ShieldCheck size={18} />
                            <span>Proceed to Payment</span>
                        </button>
                    </div>
                </div>

            </div>

            {/* KHQR Modal */}
            {khqrModalOpen && khqrData && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
                    <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" onClick={() => setKhqrModalOpen(false)}></div>
                    <div className="relative w-full max-w-sm bg-white rounded-3xl shadow-2xl p-8 flex flex-col items-center animate-in zoom-in-95 duration-200">
                        <button
                            onClick={() => setKhqrModalOpen(false)}
                            className="absolute top-4 right-4 text-slate-400 hover:text-slate-900 bg-slate-50 hover:bg-slate-100 rounded-full p-2 transition-colors"
                        >
                            <X size={20} />
                        </button>

                        <div className="w-16 h-16 bg-red-50 text-red-600 rounded-2xl flex items-center justify-center mb-6">
                            <QrCode size={32} />
                        </div>

                        <h3 className="text-xl font-bold text-slate-900 mb-2">Scan to Pay</h3>
                        <p className="text-sm text-slate-500 mb-6 text-center">Please use your banking app to scan the KHQR code below.</p>

                        <div className="bg-white p-2 rounded-2xl border-2 border-slate-100 shadow-sm mb-6 relative flex justify-center items-center">
                            <img src={khqrData.qr_image_url} alt="KHQR Code" className="w-full max-w-[240px] rounded-xl" />

                            {/* KHQR Center Logo */}
                            <div className="absolute inset-0 m-auto w-12 h-12 bg-white rounded-xl flex items-center justify-center p-[3px] shadow-sm">
                                <div className="w-full h-full bg-[#E51937] rounded-lg flex flex-col items-center justify-center text-white font-black text-[10px] leading-none tracking-tight">
                                    <span>KH</span>
                                    <span>QR</span>
                                </div>
                            </div>
                            <div className="absolute top-2 right-2 flex space-x-1">
                                <span className="flex h-3 w-3 relative">
                                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                                    <span className="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
                                </span>
                            </div>
                        </div>

                        <div className="text-center w-full">
                            <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Amount Due</div>
                            <div className="text-3xl font-bold text-slate-900 mb-6">${parseFloat(khqrData.amount).toFixed(2)}</div>
                        </div>

                        <div className="flex items-center justify-center space-x-3 text-slate-400 text-sm font-medium bg-slate-50 w-full py-4 rounded-xl border border-slate-100">
                            <Loader2 size={18} className="animate-spin text-emerald-500" />
                            <span>Awaiting payment...</span>
                        </div>
                    </div>
                </div>
            )}

            <style>{`
                .no-scrollbar::-webkit-scrollbar { display: none; }
                .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
            `}</style>
        </div>
    );
};

export default Checkout;
