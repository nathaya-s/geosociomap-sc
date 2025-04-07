// src/context/ProjectContext.tsx
import { createContext, useContext, useState, ReactNode } from 'react';
import { Project } from '../types';

interface ProjectContextType {
  project: Project | null;
  setProject: (project: Project) => void;
}

const ProjectContext = createContext<ProjectContextType | undefined>(undefined);

export const useProject = () => {
  const context = useContext(ProjectContext);
  if (!context) {
    throw new Error('useProject must be used within a ProjectProvider');
  }
  return context;
};

export const ProjectProvider = ({ children }: { children: ReactNode }) => {
  const [project, setProject] = useState<Project | null>(null);

  return (
    <ProjectContext.Provider value={{ project, setProject }}>
      {children}
    </ProjectContext.Provider>
  );
};
