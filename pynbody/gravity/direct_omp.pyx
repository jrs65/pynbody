#cython: embedsignature=True


cimport cython  
from pynbody import units, array
import numpy as np
cimport numpy as np

DTYPE = np.double
ctypedef np.double_t DTYPE_t

cdef extern from "math.h" nogil :
      DTYPE_t sqrt(DTYPE_t)

@cython.cdivision(True)
@cython.boundscheck(False)
def direct(f, np.ndarray[DTYPE_t, ndim=2] ipos, eps=None): 
    from cython.parallel cimport prange

    cdef unsigned int nips = len(ipos)
    cdef np.ndarray[DTYPE_t, ndim=2] m_by_r2 = np.zeros((nips,3), dtype = np.float64)
    cdef np.ndarray[DTYPE_t, ndim=1] m_by_r = np.zeros(nips, dtype = np.float64)
    cdef np.ndarray[DTYPE_t, ndim=2] pos = f['pos'].view(np.ndarray)
    cdef np.ndarray[DTYPE_t, ndim=1] mass = f['mass'].view(np.ndarray)
    cdef unsigned int n = len(mass)
    cdef DTYPE_t epssq = eps*eps

    cdef unsigned int pi, i
    cdef double dx, dy, dz, mass_i, drsoft, drsoft3

    for pi in prange(nips,nogil=True,schedule='static'):
        for i in range(n):
            mass_i = mass[i]
            dx = ipos[pi,0] - pos[i,0]
            dy = ipos[pi,1] - pos[i,1]
            dz = ipos[pi,2] - pos[i,2]
            drsoft = 1.0/sqrt(dx*dx + dy*dy + dz*dz + epssq)
            drsoft3 = drsoft*drsoft*drsoft
            m_by_r[pi] += mass_i * drsoft
            m_by_r2[pi,0] += mass_i*dx * drsoft3
            m_by_r2[pi,1] += mass_i*dy * drsoft3
            m_by_r2[pi,2] += mass_i*dz * drsoft3
            
    
    m_by_r = m_by_r.view(array.SimArray)
    m_by_r2 = m_by_r2.view(array.SimArray)
    m_by_r.units = f['mass'].units/f['pos'].units
    m_by_r2.units = f['mass'].units/f['pos'].units**2

    m_by_r*=units.G
    m_by_r2*=units.G
    
    return -m_by_r, -m_by_r2

