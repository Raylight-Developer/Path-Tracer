#include "Object/Mesh.h"

Quad::Quad() {
	vertex_a = dvec3( -0.5, 0, -0.5 );
	vertex_b = dvec3(  0.5, 0, -0.5 );
	vertex_c = dvec3(  0.5, 0,  0.5 );
	vertex_d = dvec3( -0.5, 0,  0.5 );
}