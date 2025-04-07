import { useRouter } from 'next/router';
import { signOut } from 'firebase/auth';
import { useState } from 'react';
import { auth } from '../firebase';

const LogoutButton = () => {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const handleLogout = async () => {
    setLoading(true);
    try {
      await signOut(auth); 
      router.push('/login'); 
    } catch (error) {
      console.error('Error logging out: ', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      onClick={handleLogout}
      disabled={loading}
      className="bg-red-500 text-white py-2 px-4 rounded hover:bg-red-600 transition"
    >
      {loading ? 'Logging out...' : 'Logout'}
    </button>
  );
};

export default LogoutButton;
