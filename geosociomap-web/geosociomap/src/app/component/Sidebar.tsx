import { useEffect, useState } from "react";
import { Sarabun } from "next/font/google";
import React from "react";
import { useMapContext } from "../contexts/MapContext";
import axios from "axios";
import { useRouter } from "next/navigation";
import { useAuth } from "../hooks/useAuth";
import { Cancel } from "@mui/icons-material";

const sarabun = Sarabun({
  weight: ["400", "500", "600", "700"],
  subsets: ["thai", "latin"],
  display: "swap",
});

// interface SidebarProps {
//   points?: [number, number][];
// }

const Sidebar: React.FC = () => {
  const { points } = useMapContext();
  const [projectName, setProjectName] = useState("");
  // const [userId, setUserId] = useState("");
  const router = useRouter();
  const { user } = useAuth();

  // const toggleAddingPoints = () => {
  //   setIsAddingPoints(!isAddingPoints);
  // };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      const response = await axios.post(
       `${API_BASE_URL}/create-project`,
        {
          projectName,
          userId: user?.uid,
          selectedPoints: points.map(([lng, lat]) => ({ lat, lng })),
          selectedEmails: selectedEmails,
        }
      );

      console.log("Project created successfully:", response.data);
      router.push("/main");
    } catch (error) {
      console.error("Failed to create project:", error);
    }
  };

  const [email, setEmail] = useState("");
  const [allEmails, setAllEmails] = useState<string[]>([]);
  const [searchResults, setSearchResults] = useState<string[]>([]);
  const [selectedEmails, setSelectedEmails] = useState<string[]>([]);

  useEffect(() => {
    const fetchAllEmails = async () => {
      try {
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const response = await fetch(`${API_BASE_URL}/users/emails`);
        const data = await response.json();
        setAllEmails(data.emails || []);
      } catch (error) {
        console.error("Error fetching all emails:", error);
      }
    };

    fetchAllEmails();
  }, []);

  const handleSearch = (query: string) => {
    setEmail(query);

    if (query.length > 2) {
      const results = allEmails.filter((email) =>
        email.toLowerCase().includes(query.toLowerCase())
      );
      setSearchResults(results); 
    } else {
      setSearchResults([]); 
    }
  };

  const handleSelect = (selectedEmail: string) => {
    setSelectedEmails((prev) => [...prev, selectedEmail]); 
    setEmail("");
    setSearchResults([]); 
  };

  const handleRemove = (emailToRemove: string) => {
    setSelectedEmails((prev) =>
      prev.filter((email) => email !== emailToRemove)
    );
  };

  return (
    <div
      className={`absolute  top-0 left-0 w-64 h-full bg-white shadow-lg z-10 h-screen rounded-2xl w-96 bg-neutral-100 text-stone-700 flex flex-col ${sarabun.className}`}
    >
      <form
        className="h-full p-4  grid content-between"
        onSubmit={handleSubmit}
      >
        <div className="overflow-y-auto">
          <div className="py-4 font-bold text-xl text-blue-600 ">
            สร้างโครงการ
          </div>

          <div className="flex flex-col gap-4 ">
            <div>
              <label className="text-gray-800 text-sm mb-2 block">
                ชื่อโครงการ
              </label>
              <div className="relative flex items-center">
                <input
                  name="projectName"
                  value={projectName}
                  onChange={(e) => setProjectName(e.target.value)}
                  required
                  className="w-full text-sm text-stone-800 border border-gray-300 px-4 py-3 rounded-lg outline-blue-600"
                  placeholder="ชื่อโครงการ"
                />
              </div>
            </div>
            <div>
              <label className="text-gray-800 text-sm mb-2 block">
                เพิ่มสมาชิก
              </label>
              <div className="relative flex items-center">
                <input
                  name="Team"
                  value={email}
                  onChange={(e) => handleSearch(e.target.value)}
                  className="w-full text-sm text-stone-800 border border-gray-300 px-4 py-3 rounded-lg outline-blue-600"
                  placeholder="เพิ่มสมาชิก"
                />
              </div>
              {searchResults.length > 0 && (
                <ul className="absolute mt-2 bg-white border border-gray-300 rounded-lg w-full z-10">
                  {searchResults.map((result, index) => (
                    <li
                      key={index}
                      onClick={() => handleSelect(result)}
                      className="px-4 py-2 hover:bg-gray-100 cursor-pointer"
                    >
                      {result}
                    </li>
                  ))}
                </ul>
              )}

              {selectedEmails.length > 0 && (
                <div className="mt-4  text-sm justify-center">
                  <h3 className="text-gray-800 text-sm mb-2">สมาชิกที่เลือก</h3>
                  <table className="w-full border">
                    <thead>
                      <tr className="w-full bg-gray-100  border-gray-200">
                        <th className=" border-b border-gray-300 px-4 py-2 text-left">
                          ลำดับ
                        </th>
                        <th className=" border-b border-gray-300 px-4 py-2 text-left">
                          Email
                        </th>
                        <th className=" border-b border-gray-300 px-4 py-2 text-left"></th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedEmails.map((email, index) => (
                        <tr key={index}>
                          <td className="border-b px-4 py-2">{index + 1}</td>
                          <td className="border-b px-4 py-2">{email}</td>
                          <td className="border-b px-4 py-2 flex items-center justify-center">
                            <button
                              onClick={() => handleRemove(email)}
                              className=""
                            >
                              <Cancel className="text-stone-400" />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
            <div className="text-stone-800 text-sm py-1">
              เลือกพื้นที่
              <div className="overflow-x-auto text-stone-500 text-sm">
                คลิกบนแผนที่เพื่อสร้างพื้นที่
                <table className="min-w-full bg-white border border-gray-200">
                  <thead>
                    <tr className="w-full bg-gray-100 border-b border-gray-200">
                      <th className="py-2 px-4 text-left text-gray-700">จุด</th>
                      <th className="py-2 px-4 text-left text-gray-700">
                        ละติจูด
                      </th>
                      <th className="py-2 px-4 text-left text-gray-700">
                        ลองจิจูด
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {points.length === 0 ? (
                      <tr className="">
                        <td className="py-2 px-4"></td>
                        <td className="py-2 px-4"></td>
                        <td className="py-2 px-4"></td>
                      </tr>
                    ) : (
                      points.map((row, index) => (
                        <tr key={index} className="border-b border-gray-200,">
                          <td className="py-2 px-4">{index + 1}</td>
                          <td className="py-2 px-4">{row[1].toPrecision(6)}</td>
                          <td className="py-2 px-4">{row[0].toPrecision(7)}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          {/* <div className="text-gray-800 text-sm flex justify-end">
            <div
              className="flex w-20 p-2 bg-blue-600 hover:bg-blue-500 text-white rounded justify-center cursor-pointer "
              onClick={toggleAddingPoints}
            >
              {isAddingPoints ? "บันทึก" : "เลือกพื้นที่"}
            </div>
          </div> */}
        </div>

        <div className="mt-4">
          <button
            type="submit"
            className="p-2 bg-blue-600 text-white rounded w-full hover:bg-blue-500 transition"
            // onClick={() => alert("Create Project button clicked")}
          >
            บันทึก
          </button>
        </div>
      </form>
    </div>
  );
};

export default Sidebar;
