// components/MapCard.tsx
import React, { useState } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import { Delete, Cancel, Edit } from "@mui/icons-material";
import { useRouter } from "next/navigation";
import { Project } from "../types";
import Image from 'next/image';
// import { Delete } from "@mui/icons-material";

interface MapCardProps {
  project: Project;
  title: string;
  createdAt: string;
  lastUpdate: string;
  center: [number, number];
  setting: boolean;
  projects: Project[];
  setProjects: React.Dispatch<React.SetStateAction<Project[]>>;
}

mapboxgl.accessToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || "";

const MapCard: React.FC<MapCardProps> = ({
  project,
  title,
  createdAt,
  lastUpdate,
  // center,
  setting,
  projects,
  setProjects,
}) => {
  // const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const imageUrl =
    "https://drive.google.com/uc?export=view&id=1zUzb4XQbRheX04mxrSjnKN3jT9z73viO";
   
  // useEffect(() => {
  //   if (mapContainerRef.current) {
  //     if (
  //       center &&
  //       center.length === 2 &&
  //       !isNaN(center[0]) &&
  //       !isNaN(center[1])
  //     ) {
  //       const map = new mapboxgl.Map({
  //         container: mapContainerRef.current,
  //         style: "mapbox://styles/mapbox/streets-v11",
  //         center: center,
  //         zoom: 15,
  //         interactive: false,
  //         scrollZoom: false,
  //         dragPan: false,
  //         dragRotate: false,
  //         keyboard: false,
  //       });

  //       new mapboxgl.Marker().setLngLat(center).addTo(map);
  //       return () => map.remove();
  //     }
  //   }
  // }, [center]);

  const router = useRouter();
  const handleEditClick = (project: Project) => {
    router.push(`/editProject?id=${project._id}`);
  };

  const handleDeleteClick = async (projectId: string) => {
    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      const response = await fetch(
       `${API_BASE_URL}/projects/${projectId}`,
        {
          method: "DELETE",
        }
      );

      if (response.ok) {
        setProjects(projects.filter((proj) => proj._id !== projectId));
        // alert("Project deleted successfully");
      } else {
        const errorData = await response.json();
        alert(`Error: ${errorData.message}`);
      }
    } catch (error) {
      console.error("Error deleting project:", error);
      alert("Error deleting project");
    }
  };

  return (
    <div className="w-72 shadow-lg rounded overflow-hidden">
      {setting ? (
        <div className="flex justify-end  gap-2">
          <button
            onClick={() => handleEditClick(project)}
            className="text-blue-400 text-xs"
          >
            <Edit />
          </button>
          <div className="text-blue-400 text-xs">
            <button onClick={() => setIsModalOpen(true)}>
              <Delete />
            </button>
          </div>
        </div>
      ) : (
        <div></div>
      )}

      <div className="w-full h-52">
        <Image src={imageUrl}
          alt="Descriptive Alt Text"
          height={100} width={200}
          className="w-full h-full object-cover"
        />
      </div>
      <div className="p-5">
        <div className="flex justify-between items-center">
          <h3 className="text-lg font-bold text-blue-600 truncate">{title}</h3>
        </div>

        {/* <p className="mt-2 text-sm text-blue-600">แก้ไขล่าสุด</p> */}
        <div className="flex justify-between mt-2">
          <div className="text-stone-600 text-sm">สร้างเมื่อ</div>
          <div className="text-stone-600 text-sm">{createdAt}</div>
        </div>
        <div className="flex justify-between mt-2">
          <button className="text-stone-600 text-sm">แก้ไขล่าสุด</button>
          <button className="text-stone-600 text-sm">{lastUpdate}</button>
        </div>
      </div>
      {isModalOpen && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
          <div className="bg-white p-6 rounded-lg w-80">
            <div className="flex justify-center mb-4">
              <Cancel className="text-red-500" style={{ fontSize: "60px" }} />
            </div>
            <h3 className="text-lg text-center mb-4">ยืนยันการลบโครงการ</h3>
            <div className="flex justify-between gap-4">
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-gray-700 text-xs px-4 py-3  w-[47%] rounded-full transition-colors duration-300 bg-gray-300 hover:bg-gray-200"
              >
                ยกเลิก
              </button>
              <button
                onClick={() => {
                  handleDeleteClick(project._id);
                  setIsModalOpen(false);
                }}
                className="text-white text-xs px-4 py-3   w-[47%] rounded-full transition-colors duration-300 bg-red-400 hover:bg-red-300"
              >
                ยืนยัน
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MapCard;
