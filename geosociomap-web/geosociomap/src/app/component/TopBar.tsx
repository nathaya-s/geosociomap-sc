import React, { useRef } from "react";
import { useEffect, useState } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { auth } from "../firebase";
import ArrowDropDownIcon from "@mui/icons-material/ArrowDropDown";
import { useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { Abril_Fatface } from "next/font/google";

const yesevaOne =  Abril_Fatface({
  weight: ["400"],
  style: ["normal"],
  subsets: ['latin'],
});

const TopBar: React.FC = () => {
  
  const [user, setUser] = useState<User | null>(null);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  // const [load, setLoading] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      if (currentUser) {
        setUser(currentUser);
      } else {
        setUser(null);
      }
    });
    return () => unsubscribe();
  }, []);

  const handleLogout = async () => {
    console.log("handleLogout");
    try {
      await signOut(auth);
      router.push("/login");
    } catch (error) {
      console.error("Error logging out: ", error);
    }
  };

  const getUserName = (email: string | null) => {
    if (!email) return "";
    return email.split("@")[0];
  };

  const toggleDropdown = () => {
    setIsDropdownOpen(!isDropdownOpen);
  };

  // const handleClickOutside = (event: MouseEvent) => {
  //   if (
  //     dropdownRef.current &&
  //     !dropdownRef.current.contains(event.target as Node)
  //   ) {
  //     setIsDropdownOpen(false);
  //   }
  // };

  //   useEffect(() => {
  //     const handleClickOutside = (event: MouseEvent) => {
  //       if (
  //         dropdownRef.current &&
  //         !dropdownRef.current.contains(event.target as Node)
  //       ) {
  //         setIsDropdownOpen(false);
  //       }
  //     };

  //     document.addEventListener("mousedown", handleClickOutside);
  //     return () => {
  //       document.removeEventListener("mousedown", handleClickOutside);
  //     };
  //   }, []);
  
  return (
    <header className="flex py-2 px-4 w-full justify-between items-center fixed bg-white border-b border-neutral-200">
      <div className="w-8 h-8">
        <div className={`${yesevaOne.className} text-blue-500 text-xl`}>geosociomap</div>
        {/* <Link href="/">
          <a>MyWebsite</a>
        </Link> */}
      </div>
      <nav>
        <ul>
          <li>
            {/* <Link href="/about">
              <a>About</a>
            </Link> */}
          </li>
          <li>
            {/* <Link href="/projects">
              <a>Projects</a>
            </Link> */}
          </li>
          <div
            onClick={toggleDropdown}
            ref={dropdownRef}
            className="flex px-3 py-1 justify-center rounded-full hover:bg-stone-50 text-sm items-stretch border border-blue-300 cursor-pointer"
          >
            {user && <div>{getUserName(user.email)}</div>}
            <ArrowDropDownIcon className="text-blue-600" />
          </div>
          {/* Dropdown Menu */}
          {isDropdownOpen && (
            <div className="absolute mt-2 w-36 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-10">
              <ul className="py-1" role="menu">
                {/* <a
                  href="#"
                  className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  role="menuitem"
                >
                  ตั้งค่า
                </a> */}
                <button
                  onClick={handleLogout}
                  className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                >
                  ออกจากระบบ
                </button>
              </ul>
            </div>
          )}
        </ul>
      </nav>
    </header>
  );
};

export default TopBar;
