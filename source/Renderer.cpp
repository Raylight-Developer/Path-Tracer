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

	iTime = 0.0;
	iFrame = 0;
	iResolution = uvec2(860, 540);

	camera = Camera();

	keys = vector(348, false);
	camera_move_sensitivity = 0.05;
	camera_view_sensitivity = 0.05;
	last_mouse = dvec2(iResolution) / 2.0;

	VAO_main       = VAO();
	VBO_main       = VBO();
	Faces          = EBO();
	buffer_tex_a   = FBT();
	last_frame_tex = FBT();
	FBO_main       = FBO();
	Buffer_A   = Shader_Program("Buffer A");
	Main_Image = Shader_Program("Main Image");

	pause = false;
}

void Renderer::recompile() {
	Buffer_A.ReCompile();
	Main_Image.ReCompile();

	FBO_main.Bind();
	buffer_tex_a.Resize(iResolution);
	FBO_main.Unbind();
	last_frame_tex.Resize(iResolution);

	iFrame = 0;
	iTime = glfwGetTime();
}

void Renderer::framebuffer_size_callback(GLFWwindow* window, int width, int height) {
	Renderer* instance = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
	glViewport(0, 0, width, height);
	instance->iResolution.x = width;
	instance->iResolution.y = height;
	instance->iFrame = 0;
	instance->iTime = glfwGetTime();

	instance->FBO_main.Bind();
	instance->buffer_tex_a.Resize(uvec2(width, height));
	instance->FBO_main.Unbind();
	instance->last_frame_tex.Resize(uvec2(width, height));
}

void Renderer::cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
	Renderer* instance = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
	if (instance->keys[GLFW_MOUSE_BUTTON_RIGHT]) {
		float xoffset = xpos - instance->last_mouse.x;
		float yoffset = instance->last_mouse.y - ypos;

		instance->last_mouse = dvec2(xpos, ypos);

		instance->camera.rotate(xoffset * instance->camera_view_sensitivity, yoffset * instance->camera_view_sensitivity * 2.5);
	}
}

void Renderer::mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {
	Renderer* instance = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
	if (action == GLFW_PRESS) {
		instance->keys[button] = true;
		if (button == GLFW_MOUSE_BUTTON_RIGHT) {
			double xpos, ypos;
			glfwGetCursorPos(window, &xpos, &ypos);
			instance->last_mouse = dvec2(xpos, ypos);
			glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
		}
	}
	else if (action == GLFW_RELEASE) {
		instance->keys[button] = false;
		if (button == GLFW_MOUSE_BUTTON_RIGHT) {
			double xpos, ypos;
			glfwGetCursorPos(window, &xpos, &ypos);
			instance->last_mouse = dvec2(xpos, ypos);
			glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
		}
	}
}

void Renderer::scroll_callback(GLFWwindow* window, double xoffset, double yoffset) {
	Renderer* instance = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
	if (yoffset < 0) {
		instance->camera_move_sensitivity /= 1.1;
	}
	if (yoffset > 0) {
		instance->camera_move_sensitivity *= 1.1;
	}
}

void Renderer::key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	Renderer* instance = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
	if (key == GLFW_KEY_R && action == GLFW_PRESS) {
		instance->recompile();
	}
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, GLFW_TRUE);
	}
	if (key == GLFW_KEY_P && action == GLFW_PRESS) {
		instance->pause = !instance->pause;
	}
	if (action == GLFW_PRESS) {
		instance->keys[key] = true;
	}
	else if (action == GLFW_RELEASE) {
		instance->keys[key] = false;
	}
}

void Renderer::Init() {
	glfwInit();

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	GLFWwindow* window = glfwCreateWindow(iResolution.x, iResolution.y, "GLSL Renderer", NULL, NULL);

	if (window == NULL) {
		cout << "Failed to create GLFW window" << endl;
		glfwTerminate();
	}

	glfwMakeContextCurrent(window);
	gladLoadGL();

	glfwSetWindowUserPointer(window, this);

	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
	glfwSetCursorPosCallback(window, cursor_position_callback);
	glfwSetMouseButtonCallback(window, mouse_button_callback);
	glfwSetScrollCallback(window, scroll_callback);
	glfwSetKeyCallback(window, key_callback);

	glViewport(0, 0, iResolution.x , iResolution.y);

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
	buffer_tex_a.Init(iResolution);
	FBO_main.Unbind();

	last_frame_tex.Init(iResolution);

	glClearColor(0, 0, 0, 1);
	while (!glfwWindowShouldClose(window)) {
		if (!pause) {
			// Input Handling
			if (keys[GLFW_KEY_D])
				camera.move( 1, 0, 0, camera_move_sensitivity);
			if (keys[GLFW_KEY_A])
				camera.move(-1, 0, 0, camera_move_sensitivity);
			if (keys[GLFW_KEY_E] || keys[GLFW_KEY_SPACE])
				camera.move(0,  1, 0, camera_move_sensitivity);
			if (keys[GLFW_KEY_Q] || keys[GLFW_KEY_LEFT_CONTROL])
				camera.move(0, -1, 0, camera_move_sensitivity);
			if (keys[GLFW_KEY_W])
				camera.move(0, 0,  1, camera_move_sensitivity);
			if (keys[GLFW_KEY_S])
				camera.move(0, 0, -1, camera_move_sensitivity);

			double Time = glfwGetTime() - iTime;
			FBO_main.Bind();
			glClear(GL_COLOR_BUFFER_BIT);
			Buffer_A.Activate();
			VAO_main.Bind();

			glUniform1f (glGetUniformLocation(Buffer_A.ID, "iTime"),       GLfloat(Time));
			glUniform1ui(glGetUniformLocation(Buffer_A.ID, "iFrame"),      GLuint(iFrame));
			glUniform2fv(glGetUniformLocation(Buffer_A.ID, "iResolution"), 1, value_ptr(vec2(iResolution)));

			glUniform1f (glGetUniformLocation(Buffer_A.ID, "iCameraFocalLength"), GLfloat(camera.Focal_Length));
			glUniform1f (glGetUniformLocation(Buffer_A.ID, "iCameraSensorWidth"), GLfloat(camera.Sensor_Width));
			glUniform3fv(glGetUniformLocation(Buffer_A.ID, "iCameraPos"),   1, value_ptr(vec3(camera.Pos)));
			glUniform3fv(glGetUniformLocation(Buffer_A.ID, "iCameraFront"), 1, value_ptr(vec3(camera.Z_Vec)));
			glUniform3fv(glGetUniformLocation(Buffer_A.ID, "iCameraUp"),    1, value_ptr(vec3(camera.Y_Vec)));
			last_frame_tex.Bind(GL_TEXTURE0);

			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

			glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, iResolution.x, iResolution.y);
			last_frame_tex.Unbind();

			FBO_main.Unbind();

			Main_Image.Activate();

			glUniform1f (glGetUniformLocation(Main_Image.ID, "iTime"),       GLfloat(Time));
			glUniform1ui(glGetUniformLocation(Main_Image.ID, "iFrame"),      GLuint(iFrame));
			glUniform2fv(glGetUniformLocation(Main_Image.ID, "iResolution"), 1, value_ptr(vec2(iResolution)));
			buffer_tex_a.Bind(GL_TEXTURE0);

			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

			iFrame++;
		}
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
}