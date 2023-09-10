#include "Renderer.h"

Renderer::Renderer() {
	vertices = {
		-1.0f, -1.0f, 0.0f, 0.0f,
		 1.0f, -1.0f, 1.0f, 0.0f,
		 1.0f,  1.0f, 1.0f, 1.0f,
		-1.0f,  1.0f, 0.0f, 1.0f,
	};
	faces = {
		0, 1, 2,
		2, 3, 0
	};
	iResolution_x = 860;
	iResolution_y = 540;
	iFrame = 0;
	iTime = 0.0;
	pause = false;
	frame_advance = false;

	VAO_main = VAO();
	VBO_main = VBO();
	Faces = EBO();

	buffer_tex_a = FBT();
	last_frame_tex = FBT();
	FBO_main = FBO();
	Buffer_A = Shader_Program("Buffer A");
	Main_Image = Shader_Program("Main Image");
}

void Renderer::recompile() {
	Buffer_A.ReCompile();
	Main_Image.ReCompile();

	FBO_main.Bind();
	buffer_tex_a.Resize(iResolution_x, iResolution_y);
	FBO_main.Unbind();
	last_frame_tex.Resize(iResolution_x, iResolution_y);

	iFrame = 0;
	iTime = glfwGetTime();
}

void Renderer::framebuffer_size_callback(GLFWwindow* window, int width, int height) {
	Renderer* instance = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
	glViewport(0, 0, width, height);
	instance->iResolution_x = width;
	instance->iResolution_y = height;
	instance->iFrame = 0;
	instance->iTime = glfwGetTime();

	instance->FBO_main.Bind();
	instance->buffer_tex_a.Resize(width, height);
	instance->FBO_main.Unbind();
	instance->last_frame_tex.Resize(width, height);
}

void Renderer::key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	Renderer* instance = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
	if (key == GLFW_KEY_R && action == GLFW_PRESS) {
		instance->recompile();
	}
	if (key == GLFW_KEY_P && action == GLFW_PRESS) {
		instance->pause = !instance->pause;
	}
	if (key == GLFW_KEY_PERIOD && action == GLFW_PRESS) {
		instance->frame_advance = true;
	}
}

void Renderer::Init() {
	glfwInit();

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	GLFWwindow* window = glfwCreateWindow(iResolution_x, iResolution_y, "GLSL Renderer", NULL, NULL);

	if (window == NULL) {
		cout << "Failed to create GLFW window" << endl;
		glfwTerminate();
	}

	glfwMakeContextCurrent(window);
	gladLoadGL();

	glfwSetWindowUserPointer(window, this);
	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
	glfwSetKeyCallback(window, key_callback);

	glViewport(0, 0, iResolution_x, iResolution_y);

	// Generates Shader object using shaders defualt.vert and default.frag
	Buffer_A.Init("./resources/Shaders/Buffer_A.glsl");
	Main_Image.Init("./resources/Shaders/Main_Image.glsl");

	// VERTICES //
		// VAO Bind
	VAO_main.Init();
	VAO_main.Bind();
		// VBO Init
	VBO_main.Init(vertices.data(), vertices.size() * sizeof(float));
		// EBO Init
	Faces.Init(faces.data(), faces.size() * sizeof(float));
		// VAO Link
	VAO_main.LinkAttrib(VBO_main, 0, 2, GL_FLOAT, 4 * sizeof(GLfloat), (void*)0);
	VAO_main.LinkAttrib(VBO_main, 1, 2, GL_FLOAT, 4 * sizeof(GLfloat), (void*)(2 * sizeof(float)));

	VAO_main.Unbind();
	VBO_main.Unbind();
	Faces.Unbind();

	// FBOs //
		// FBO Init
	FBO_main.Init();
	FBO_main.Bind();
	buffer_tex_a.Init(iResolution_x, iResolution_y);
	FBO_main.Unbind();

	last_frame_tex.Init(iResolution_x, iResolution_y);

	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	while (!glfwWindowShouldClose(window)) {
		if (!pause) {
			double Time = glfwGetTime() - iTime;
			FBO_main.Bind();
			glClear(GL_COLOR_BUFFER_BIT);
			Buffer_A.Activate();
			VAO_main.Bind();

			glUniform1f(glGetUniformLocation(Buffer_A.ID, "iTime"), float(Time));
			glUniform1ui(glGetUniformLocation(Buffer_A.ID, "iFrame"), GLuint(iFrame));
			glUniform2f(glGetUniformLocation(Buffer_A.ID, "iResolution"), iResolution_x, iResolution_y);
			last_frame_tex.Bind(GL_TEXTURE0);

			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

			glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, iResolution_x, iResolution_y);
			last_frame_tex.Unbind();

			FBO_main.Unbind();

			Main_Image.Activate();

			glUniform1f(glGetUniformLocation(Main_Image.ID, "iTime"), float(Time));
			glUniform1ui(glGetUniformLocation(Main_Image.ID, "iFrame"), GLuint(iFrame));
			glUniform2f(glGetUniformLocation(Main_Image.ID, "iResolution"), iResolution_x, iResolution_y);
			buffer_tex_a.Bind(GL_TEXTURE0);

			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

			iFrame++;
		}
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
}