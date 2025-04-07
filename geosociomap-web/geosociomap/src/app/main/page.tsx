"use client";

import { useAuth } from "../hooks/useAuth";
import { useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import TopBar from "../component/TopBar";
import { Sarabun } from "next/font/google";
import SettingsIcon from "@mui/icons-material/Settings";
import MapCard from "../component/Mapcard";
import { Cancel } from "@mui/icons-material";
import Publish from "@mui/icons-material/Publish";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import { Project } from "../types";
import Create from "@mui/icons-material/Create";
import { Layer } from "../types/layer";
import axios from "axios";

const sarabun = Sarabun({
  weight: ["400", "500", "600", "700"],
  subsets: ["thai", "latin"],
  display: "swap",
});

interface Point {
  lat: number;
  lng: number;
}

const MainPage: React.FC = () => {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const { user, loading } = useAuth();
  // const [load, setLoading] = useState(false);
  const [setting, setSetting] = useState(false);
  const router = useRouter();
  const [projects, setProjects] = useState<Project[]>([]);
  // const [error, setError] = useState<string | null>(null);
  const [layers, setLayers] = useState<Layer[]>([]);

  const [popupVisible, setPopupVisible] = useState(false);
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);
  useEffect(() => {
    if (mapContainerRef.current && selectedProject) {
      const map = new mapboxgl.Map({
        container: mapContainerRef.current,
        style: "mapbox://styles/mapbox/streets-v11",
        center: getCentroid(selectedProject.selectedPoints) || [
          100.523186, 13.736717,
        ],
        zoom: 15,
        interactive: false,
        scrollZoom: false,
        dragPan: false,
        dragRotate: false,
        keyboard: false,
      });

      new mapboxgl.Marker()
        .setLngLat(getCentroid(selectedProject.selectedPoints))
        .addTo(map);
      return () => map.remove();
    }
  }, [selectedProject]);

  const handleCardClick = (project: Project) => {
    setSelectedProject(project); 
    setPopupVisible(true); 
  };

  const closePopup = () => {
    setPopupVisible(false);
    setSelectedProject(null); 
  };

  const EditCardClick = (project: Project) => {
    router.push(`/project?id=${project._id}`);
  };

  const monthNamesThai = [
    "มกราคม",
    "กุมภาพันธ์",
    "มีนาคม",
    "เมษายน",
    "พฤษภาคม",
    "มิถุนายน",
    "กรกฎาคม",
    "สิงหาคม",
    "กันยายน",
    "ตุลาคม",
    "พฤศจิกายน",
    "ธันวาคม",
  ];

  const formatDateToThai = (isoDate: string): string => {
    const date = new Date(isoDate);
    const day = date.getDate();
    const month = monthNamesThai[date.getMonth()];
    const year = date.getFullYear() + 543; 

    return `${day} ${month} ${year}`;
  };

  const getCentroid = (points: Point[]): [number, number] => {
    const totalPoints = points.length;

    const sum = points.reduce(
      (acc, point) => {
        return {
          lat: acc.lat + point.lat,
          lng: acc.lng + point.lng,
        };
      },
      { lat: 0, lng: 0 }
    );

    const centroid = {
      lat: sum.lat / totalPoints,
      lng: sum.lng / totalPoints,
    };
    console.log([centroid.lng, centroid.lat]);
    return [centroid.lng, centroid.lat];
  };

  const goToCreateProject = () => {
    router.push("/createProject");
  };

  useEffect(() => {
    console.log(user?.uid);
    const fetchProjects = async (userId: string) => {
      try {
        // console.log(`https://geosociomap-backend.onrender.com/projects/${userId}`);
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const response = await fetch(
          `${API_BASE_URL}/projects/${userId}`
        );
        if (!response.ok) {
          throw new Error("Network response was not ok");
        }
        const data = await response.json();
        setProjects(data);
        console.log(projects);
      } catch (error) {
        console.error(error);
      } 
    };

    fetchProjects(user?.uid || "");
  }, [user]);

  useEffect(() => {
    if (selectedProject?._id && user?.uid) {
      // setLoading(true); 
      // console.log( `https://geosociomap-backend.onrender.com/layers/${selectedProject?._id}?userId=${user?.uid}`)
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      fetch(
        `${API_BASE_URL}/layers/${selectedProject?._id}?userId=${user?.uid}`
      )
        .then((response) => response.json())
        .then((data) => {
          console.log("Fetched layers:", data);
          setLayers(data); 
        })
        .catch((error) => {
          console.error("Error fetching layers:", error);
        });
    }
  }, [selectedProject?._id, user?.uid]);

  useEffect(() => {
    console.log(projects);
  }, [projects]);

  useEffect(() => {
    if (!loading && !user) {
      router.push("/login");
    }
  }, [loading, user, router]);

  if (loading) return <p>Loading...</p>;

  if (!user) return null;

  const toggleSetting = () => {
    setSetting(!setting);
  };

  const handleShare = async (layer: Layer) => {
    try {
      // setLoading(true);
      // setError(null);

      const layerData = {
        projectId: selectedProject?._id,
        layer,
        userId: user.uid,
      };
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL

      const response = await axios.post(
       `${API_BASE_URL}/share-layer`,
        layerData
      );

      if (response.status === 201) {
        console.log("Layer added and shared successfully", response.data);
        // const updatedLayer = response.data.layers;

        setLayers((prevLayers) =>
          prevLayers.map((existingLayer) =>
            existingLayer.id === layer.id
              ? {
                  ...existingLayer,
                  sharedWith:
                    selectedProject?.userIds.filter(
                      (userId) =>
                        String(userId).toLowerCase() !==
                        user?.email?.toLowerCase() 
                    ) || [],
                }
              : existingLayer
          )
        );
      } else {
        // setError("Failed to share the layer");
      }
    } catch (err) {
      console.error("Error sharing layer:", err);
      // setError("Failed to share the layer");
    } 
  };

  return (
    <div className={`${sarabun.className}`}>
      <TopBar />
      <div className="h-dvh flex flex-col gap-4 pt-16 px-4 bg-stone-50">
        <div className="flex justify-between">
          <div></div>
          <div className="flex flex-row gap-4 content-center items-center justify-between ">
            <button
              onClick={() => toggleSetting()}
              className="py-3 px-3 flex flex-row gap-1 rounded-full content-center items-center text-sm text-stone-500 hover:text-stone-600 transition"
            >
              <SettingsIcon />
              ตั้งค่าโครงการ
            </button>
            <button
              type="button"
              onClick={goToCreateProject}
              className="w-50 shadow-xl py-3 px-4 text-sm tracking-wide rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none transition"
            >
              เพิ่มโครงการ
            </button>
          </div>
        </div>
        <div
          className="grid 
                grid-cols-1     
                sm:grid-cols-2   
                md:grid-cols-3   
                lg:grid-cols-4 
                xl:grid-cols-5  
                gap-4"
        >
          {projects.length === 0 && !loading && <p>ไม่มีโครงการ</p>}
          {projects.length > 0 && (
            <>
              {projects.map((project) => (
                <div
                  key={project._id}
                  onClick={() => handleCardClick(project)}
                  className="cursor-pointer"
                >
                  <MapCard
                    key={project._id}
                    project={project}
                    title={project.projectName}
                    createdAt={formatDateToThai(project.createdAt)}
                    center={getCentroid(project.selectedPoints)}
                    lastUpdate={formatDateToThai(project.createdAt)}
                    setting={setting}
                    projects={projects}
                    setProjects={setProjects}
                  />
                </div>
              ))}
            </>
          )}
        </div>
      </div>
      {popupVisible && selectedProject && !setting && (
       <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-40">
       <div className="bg-white p-6 rounded-lg shadow-lg w-3/6 max-h-[80vh] overflow-y-auto">
         <div className="flex justify-end w-full">
           <button onClick={closePopup} className="">
             <Cancel className="text-stone-400" />
           </button>
         </div>
         <div className="grid grid-cols-1 divide-y">
           <div className="flex gap-4 pb-4">
             <div ref={mapContainerRef} className="w-48 h-40 rounded" />
             <div className="flex flex-col justify-around">
               <div className="">
                 <div className="font-semibold">
                   {selectedProject.projectName}
                 </div>
                 <div>
                   แก้ไขล่าสุด {formatDateToThai(selectedProject.createdAt)}
                 </div>
               </div>
               <div className="flex gap-2 text-sm">
                 {selectedProject.userIds.map((email, index) => (
                   <div
                     key={index}
                     className="py-1 px-2 bg-blue-100 text-blue-800 rounded-full border border-blue-300"
                   >
                     {email}
                   </div>
                 ))}
               </div>
             </div>
           </div>
           <div>
             <div className="flex gap-4 py-4 bg-stone-50">
               <div className="flex flex-col gap-2 px-2 w-full">
                 <div className="flex justify-between">
                   <div className="flex gap-4">
                     <div className="text-sm flex flex-col justify-center ">
                       <div className="font-semibold">
                         {selectedProject.projectName}
                       </div>
                       {user.email}
                     </div>
                   </div>
                   <div className="flex items-center gap-2 text-sm">
                     <button
                       onClick={() => EditCardClick(selectedProject)}
                       className="flex justify-center items-center w-32 rounded bg-stone-200 text-stone-600 hover:bg-stone-300 transition p-2 gap-2"
                     >
                       <Create />
                       แก้ไข
                     </button>
                   </div>
                 </div>
               </div>
             </div>
           </div>
           <div className="flex bg-stone-50 text-sm max-h-[50vh] overflow-y-auto">
             <table className="min-w-full bg-white border border-gray-200 rounded-lg shadow-sm">
               <thead className="bg-gray-100">
                 <tr>
                   <th className="py-2 px-4 text-left text-gray-700 border-b">
                     เลเยอร์
                   </th>
                   <th className="py-2 px-4 text-left text-gray-700 border-b">
                     สร้างโดย
                   </th>
                   <th className="py-2 px-4 text-left text-gray-700 border-b">
                     Shared With
                   </th>
                   <th className="py-2 px-4 text-center text-gray-700 border-b">
                     Actions
                   </th>
                 </tr>
               </thead>
               <tbody>
                 {layers.length > 0 ? (
                   layers.map((layer, index) => (
                     <tr key={index} className="border-b">
                       <td className="py-2 px-4">{layer.title}</td>
                       <td className="py-2 px-4">{user.email}</td>
                       <td className="py-2 px-4">
                         {layer.sharedWith && layer.sharedWith.length > 0
                           ? selectedProject.userIds
                               .filter(
                                 (userId) =>
                                   String(userId).toLowerCase() !==
                                   user?.email?.toLowerCase()
                               )
                               .join(", ")
                           : "Not shared"}
                       </td>
                       <td className="py-2 px-4 text-center">
                         <button
                           className="text-white px-3 py-1 rounded transition"
                           onClick={() => handleShare(layer)}
                         >
                           <Publish className="text-blue-500" />
                         </button>
                       </td>
                     </tr>
                   ))
                 ) : (
                   <tr>
                     <td
                       className="py-2 px-4 text-center text-gray-500"
                       colSpan={4}
                     >
                       No layers available
                     </td>
                   </tr>
                 )}
               </tbody>
             </table>
           </div>
         </div>
       </div>
     </div>
     
      )}
    </div>
  );
};
export default MainPage;
