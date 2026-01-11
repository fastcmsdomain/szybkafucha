// Manual mock for react-router-dom to fix Jest module resolution issues with v7
// Re-export from react-router which Jest can resolve
export {
  Routes,
  Route,
  Navigate,
  BrowserRouter,
  HashRouter,
  Link,
  NavLink,
  useNavigate,
  useLocation,
  useParams,
  useSearchParams,
} from 'react-router';
