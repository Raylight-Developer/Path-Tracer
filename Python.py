import sys
from PySide6.QtCore import *
from PySide6.QtGui import *
from PySide6.QtWidgets import *
from PySide6.QtOpenGL import *
from PySide6.QtOpenGLWidgets import *
from OpenGL.GL import *
from OpenGL.GLUT import *

import numpy as np

VERTEX_SHADER = """
	#version 450 core

	layout(location = 0) in vec2 iPos
	layout(location = 1) in vec2 iTexCoord

	out vec2 fragCoord
	out vec2 fragTexCoord

	const vec2 madd = vec2(0.5)

	void main() {
		gl_Position = vec4(iPos, 0.0, 1.0)
		fragCoord = iPos * madd + madd
		fragTexCoord = iTexCoord
	}
"""

FRAGMENT_SHADER = """
	#version 450 core

	uniform float iTime
	uniform uint iFrame
	uniform vec2 iResolution

	uniform sampler2D iLastFrame

	in vec2 fragCoord
	in vec2 fragTexCoord

	out vec4 fragColor
	void main() {
		fragColor = vec4(fragCoord.y,fragCoord.x,fragCoord.x,1)
	}
"""

POSTPROCESS_SHADER = """
	#version 450 core

	uniform float iTime
	uniform int iFrame
	uniform vec2 iResolution

	uniform sampler2D iRawFrame

	in vec2 fragCoord
	in vec2 fragTexCoord

	out vec4 fragColor

	void main() {
		fragColor = texture(iRawFrame, fragTexCoord) * 5.0
	}
"""

class OpenGLWindow(QOpenGLWidget):
	def __init__(self):
		super().__init__()

		self.vertices = np.array([
			-1.0, -1.0, 0.0, 0.0,
			 1.0, -1.0, 1.0, 0.0,
			 1.0,  1.0, 1.0, 1.0,
			-1.0,  1.0, 0.0, 1.0,
		], np.float32)

		self.faces = np.array([
			0, 1, 2,
			2, 3, 0
		], np.uint32)

		self.VAO_main: GLuint = 0
		self.VBO_main: GLuint = 0
		self.EBO_main: GLuint = 0
		self.FBO_main: GLuint = 0
		self.FBO_post: GLuint = 0
		self.Raw_Frame: GLuint = 0
		self.Last_Frame: GLuint = 0
		self.Fragment_Program: GLuint = 0
		self.PostProcess_Program: GLuint = 0

		self.iResolution_x = 860
		self.iResolution_y = 540
		self.iFrame = 0
		self.iTime = QElapsedTimer()
		self.pause = False
		self.frame_advance = False
		self.initialized = False

		self.setWindowTitle("Py OpenGL")
		self.showMaximized()

	def initializeGL(self):
		#super().initializeOpenGLFunctions()
		glViewport(0, 0, self.iResolution_x, self.iResolution_y)

		# Compile Shaders
		self.Fragment_Program = self.compileShader(self.Fragment_Program, "Main Framebuffer", FRAGMENT_SHADER)
		self.PostProcess_Program = self.compileShader(self.PostProcess_Program, "Post Process Shader", POSTPROCESS_SHADER)
		# -------------------- VAO -------------------- #
		# VAO Bind
		glGenVertexArrays(1, self.VAO_main)
		glBindVertexArray(self.VAO_main)
		# VBO Init
		glGenBuffers(1, self.VBO_main)
		glBindBuffer(GL_ARRAY_BUFFER, self.VBO_main)
		glBufferData(GL_ARRAY_BUFFER, self.vertices.size * self.vertices.itemsize, self.vertices, GL_STATIC_DRAW)
		# EBO Init
		glGenBuffers(1, self.EBO_main)
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.EBO_main)
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.faces.size * self.faces.itemsize, self.faces, GL_STATIC_DRAW)
		# VAO Link
			# Vertices
		glBindVertexArray(self.VAO_main)
		glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * self.vertices.itemsize, ctypes.c_void_p(0))
		glEnableVertexAttribArray(0)
			# Faces
		glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * self.vertices.itemsize, ctypes.c_void_p(2 * self.vertices.itemsize))
		glEnableVertexAttribArray(1)
		glBindVertexArray(0)
		# Unbind
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
		glBindBuffer(GL_ARRAY_BUFFER, 0)
		glBindVertexArray(0)
		# -------------------- FBO -------------------- #
		# FBO Init
		glGenFramebuffers(1, self.FBO_main)
		glBindFramebuffer(GL_FRAMEBUFFER, self.FBO_main)
		self.Raw_Frame = self.createFrameTexture(self.Raw_Frame)
		glBindFramebuffer(GL_FRAMEBUFFER, 0)
		# Last Frame
		glGenFramebuffers(1, self.FBO_post)
		glBindFramebuffer(GL_FRAMEBUFFER, self.FBO_post)
		self.Last_Frame = self.createFrameTexture(self.Last_Frame)
		glBindFramebuffer(GL_FRAMEBUFFER, 0)

		glClearColor(0, 0, 0, 1)
		self.initialized = True
		self.iTime.start()
	
	def paintGL(self):
		Time = self.iTime.elapsed() / 1000.0
		# Load Frame Buffer
		glBindFramebuffer(GL_FRAMEBUFFER, self.FBO_main)
		glClear(GL_COLOR_BUFFER_BIT)
		glUseProgram(self.Fragment_Program)
		glBindVertexArray(self.VAO_main)
		# Load values
		glUniform1f(glGetUniformLocation(self.Fragment_Program, "iTime"), Time)
		glUniform1ui(glGetUniformLocation(self.Fragment_Program, "iFrame"), self.iFrame)
		glUniform2f(glGetUniformLocation(self.Fragment_Program, "iResolution"), self.iResolution_x, self.iResolution_y)
		# Load last frame
		glActiveTexture(GL_TEXTURE0)
		glBindTexture(GL_TEXTURE_2D, self.Last_Frame)
		# Draw Geometry
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0)
		# Copy Render to last frame
		glBindTexture(GL_TEXTURE_2D, self.Raw_Frame)
		glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, self.iResolution_x, self.iResolution_y)
		# Switch to Post Process Shader
		glBindTexture(GL_TEXTURE_2D, 0)

		glBindFramebuffer(GL_FRAMEBUFFER, self.FBO_post)
		glUseProgram(self.PostProcess_Program)
		# Load values
		glUniform1f(glGetUniformLocation(self.PostProcess_Program, "iTime"), Time)
		glUniform1ui(glGetUniformLocation(self.PostProcess_Program, "iFrame"), self.iFrame)
		glUniform2f(glGetUniformLocation(self.PostProcess_Program, "iResolution"), self.iResolution_x, self.iResolution_y)
		# Load Raw Frame
		glActiveTexture(GL_TEXTURE0)
		glBindTexture(GL_TEXTURE_2D, self.Raw_Frame)
		# Draw Geometry
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0)

		# Swap Buffers
		glBindFramebuffer(GL_FRAMEBUFFER, 0)

		self.iFrame += 1
		if not self.pause:
			self.update()

	def resizeGL(self, w: int, h: int):
		self.iResolution_x = w
		self.iResolution_y = h
		if self.initialized:
			glViewport(0, 0, self.iResolution_x, self.iResolution_y)

			glGenFramebuffers(1, self.FBO_main)
			glBindFramebuffer(GL_FRAMEBUFFER, self.FBO_main)
			self.Raw_Frame = self.createFrameTexture(self.Raw_Frame)
			glBindFramebuffer(GL_FRAMEBUFFER, 0)

			glGenFramebuffers(1, self.FBO_post)
			glBindFramebuffer(GL_FRAMEBUFFER, self.FBO_post)
			self.Last_Frame = self.createFrameTexture(self.Last_Frame)
			glBindFramebuffer(GL_FRAMEBUFFER, 0)

			self.iTime.restart()
			self.iFrame = 0


	def recompile(self):
		self.Fragment_Program = self.compileShader(self.Fragment_Program, "Main Framebuffer", FRAGMENT_SHADER)
		self.PostProcess_Program = self.compileShader(self.PostProcess_Program, "Post Process Shader", POSTPROCESS_SHADER)

		glDeleteTextures(1, self.Raw_Frame)
		glDeleteTextures(1, self.Last_Frame)
		glDeleteFramebuffers(1, self.FBO_main)
		glDeleteFramebuffers(1, self.FBO_post)

		glGenFramebuffers(1, self.FBO_main)
		glBindFramebuffer(GL_FRAMEBUFFER, self.FBO_main)
		self.Raw_Frame = self.createFrameTexture(self.Raw_Frame)
		glBindFramebuffer(GL_FRAMEBUFFER, 0)

		glGenFramebuffers(1, self.FBO_post)
		glBindFramebuffer(GL_FRAMEBUFFER, self.FBO_post)
		self.Last_Frame = self.createFrameTexture(self.Last_Frame)
		glBindFramebuffer(GL_FRAMEBUFFER, 0)

		self.iTime.restart()
		self.iFrame = 0

	def compileShader(self, i_shader: GLuint, i_debugName: str, i_fragSource: str):
		glDeleteProgram(i_shader)

		vertShader = glCreateShader(GL_VERTEX_SHADER)
		glShaderSource(vertShader, 1, VERTEX_SHADER, None)
		glCompileShader(vertShader)
		self.debugShader(vertShader, "VERTEX " + i_debugName)

		fragShader = glCreateShader(GL_FRAGMENT_SHADER)
		glShaderSource(fragShader, 1, i_fragSource, None)
		glCompileShader(fragShader)
		self.debugShader(fragShader, "FRAGMENT " + i_debugName)

		i_shader = glCreateProgram()
		glAttachShader(i_shader, vertShader)
		glAttachShader(i_shader, fragShader)
		glLinkProgram(i_shader)
		self.debugShader(i_shader, "PROGRAM " + i_debugName)

		glDeleteShader(vertShader)
		glDeleteShader(fragShader)

		return i_shader

	def debugShader(self, i_shader: GLuint, i_type: str):
		hasCompiled: GLint
		if (i_type != "PROGRAM"):
			glGetShaderiv(i_shader, GL_COMPILE_STATUS, hasCompiled)
			if not hasCompiled:
				infoLogLength: GLint
				glGetShaderiv(i_shader, GL_INFO_LOG_LENGTH, infoLogLength)
				infoLog = ""
				glGetShaderInfoLog(i_shader, 1024, None, infoLog)
				print(f"SHADER_COMPILATION_ERROR for:  {i_type}  {infoLog}")

			glGetProgramiv(i_shader, GL_LINK_STATUS, hasCompiled)
			if not hasCompiled:
				infoLogLength: GLint
				glGetShaderiv(i_shader, GL_INFO_LOG_LENGTH, infoLogLength)
				infoLog = ""
				glGetProgramInfoLog(i_shader, 1024, None, infoLog)
				print(f"SHADER_LINKING_ERROR for:  {i_type}  {infoLog}")

	def createFrameTexture(self, io_tex: GLuint):
		glDeleteTextures(1, io_tex)
		new_ID: GLuint

		glGenTextures(1, new_ID)
		glBindTexture(GL_TEXTURE_2D, new_ID)
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.iResolution_x, self.iResolution_y, 0, GL_RGBA, GL_FLOAT, None)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, new_ID, 0)
		glBindTexture(GL_TEXTURE_2D, 0)

		return new_ID

app = QApplication(sys.argv)
window = OpenGLWindow()
sys.exit(app.exec_())