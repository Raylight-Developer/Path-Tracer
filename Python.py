import sys
import numpy as np
from PySide6.QtCore import *
from PySide6.QtGui import *
from PySide6.QtWidgets import *
from PySide6.QtOpenGL import *
from PySide6.QtOpenGLWidgets import *
from OpenGL.GL import *
from OpenGL.GLUT import *
from typing import List

VERTEX_SHADER = """
	#version 450 core

	layout(location = 0) in vec2 iPos;
	layout(location = 1) in vec2 iTexCoord;

	out vec2 fragCoord;
	out vec2 fragTexCoord;

	const vec2 madd = vec2(0.5);

	void main() {
		gl_Position = vec4(iPos, 0.0, 1.0);
		fragCoord = iPos * madd + madd;
		fragTexCoord = iTexCoord;
	}
"""

FRAGMENT_SHADER = """
	#version 450 core

	uniform float iTime;
	uniform uint iFrame;
	uniform vec2 iResolution;

	uniform sampler2D iLastFrame;

	in vec2 fragCoord;
	in vec2 fragTexCoord;

	out vec4 fragColor;
	void main() {
		fragColor = vec4(fragCoord.y,fragCoord.x,fragCoord.x,1);
	}
"""

POSTPROCESS_SHADER = """
	#version 450 core

	uniform float iTime;
	uniform int iFrame;
	uniform vec2 iResolution;

	uniform sampler2D iRawFrame;

	in vec2 fragCoord;
	in vec2 fragTexCoord;

	out vec4 fragColor;

	void main() {
		fragColor = texture(iRawFrame, fragTexCoord) * 5.0;
	}
"""

class OpenGLWindow(QOpenGLWidget):
	def __init__(self):
		super().__init__()

		self.iFrame = 0
		self.iTime = QElapsedTimer()

		self.initialized = False
		self.pause = False

		self.setWindowTitle("Py OpenGL")
		self.showMaximized()

	def initializeGL(self):
		vertex_shader = QOpenGLShader(QOpenGLShader.ShaderTypeBit.Vertex)
		vertex_shader.compileSourceCode(VERTEX_SHADER)

		fragment_shader = QOpenGLShader(QOpenGLShader.ShaderTypeBit.Fragment)
		fragment_shader.compileSourceCode(FRAGMENT_SHADER)

		postprocess_shader = QOpenGLShader(QOpenGLShader.ShaderTypeBit.Fragment)
		postprocess_shader.compileSourceCode(POSTPROCESS_SHADER)

		self.buffer_program = QOpenGLShaderProgram()
		self.buffer_program.addShader(vertex_shader)
		self.buffer_program.addShader(fragment_shader)
		self.buffer_program.link()

		self.post_process_program = QOpenGLShaderProgram()
		self.post_process_program.addShader(vertex_shader)
		self.post_process_program.addShader(postprocess_shader)
		self.post_process_program.link()

		glClearColor(0, 0, 0, 1)
		self.initialized = True
		self.iTime.start()
	
	def paintGL(self):
		glClear(GL_COLOR_BUFFER_BIT)

		# Use the shader program
		self.buffer_program.bind()

		# Create a full-screen quad
		vertices = [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0]
		vertices = (GLfloat * len(vertices))(*vertices)

		vbo = glGenBuffers(1)
		glBindBuffer(GL_ARRAY_BUFFER, vbo)
		glBufferData(GL_ARRAY_BUFFER, len(vertices) * 4, vertices, GL_STATIC_DRAW)

		vao = glGenVertexArrays(1)
		glBindVertexArray(vao)
		glEnableVertexAttribArray(0)
		glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, None)

		# Draw the quad
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)

		# Clean up
		glBindVertexArray(0)
		glBindBuffer(GL_ARRAY_BUFFER, 0)
		self.buffer_program.release()
		self.iFrame += 1

		if not self.pause:
			self.update()
		
	def resizeGL(self, w: int, h: int):
		pass

app = QApplication(sys.argv)
window = OpenGLWindow()
window.show()
sys.exit(app.exec_())