#include "Rendering/Opengl/Renderer.h"

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
	iResolution = uvec2(1920, 1080);

	camera = Camera();
	camera_change = false;

	keys = vector(348, false);
	camera_move_sensitivity = 0.15;
	camera_view_sensitivity = 0.075;
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
	Buffer_A.f_compile();
	Main_Image.f_compile();

	FBO_main.f_bind();
	buffer_tex_a.f_resize(iResolution);
	FBO_main.f_unbind();
	last_frame_tex.f_resize(iResolution);

	//camera = Camera();
	camera_change = true;
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

	instance->FBO_main.f_bind();
	instance->buffer_tex_a.f_resize(uvec2(width, height));
	instance->FBO_main.f_unbind();
	instance->last_frame_tex.f_resize(uvec2(width, height));
}

void Renderer::cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
	Renderer* instance = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
	if (instance->keys[GLFW_MOUSE_BUTTON_RIGHT]) {
		float xoffset = xpos - instance->last_mouse.x;
		float yoffset = instance->last_mouse.y - ypos;

		instance->last_mouse = dvec2(xpos, ypos);

		instance->camera.f_rotate(xoffset * instance->camera_view_sensitivity, yoffset * instance->camera_view_sensitivity);
		instance->camera_change = true;
		instance->iFrame = 0;
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
		instance->camera_change = true;
		instance->iFrame = 0;
		instance->camera_move_sensitivity /= 1.1;
	}
	if (yoffset > 0) {
		instance->camera_change = true;
		instance->iFrame = 0;
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

void Renderer::f_init() {
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
	Buffer_A.f_init("./resources/Shaders/Buffer_A.glsl");
	Main_Image.f_init("./resources/Shaders/Main_Image.glsl");

	// VERTICES //
		// VAO Bind
	VAO_main.f_init();
	VAO_main.f_bind();
		// VBO Init
	VBO_main.f_init(vertices.data(), vertices.size() * sizeof(float));
		// EBO Init
	Faces.f_init(faces.data(), faces.size() * sizeof(float));
		// VAO Link
	VAO_main.f_linkVBO(VBO_main, 0, 2, GL_FLOAT, 4 * sizeof(GLfloat), (void*)0);
	VAO_main.f_linkVBO(VBO_main, 1, 2, GL_FLOAT, 4 * sizeof(GLfloat), (void*)(2 * sizeof(float)));

	VAO_main.f_unbind();
	VBO_main.f_unbind();
	Faces.f_unbind();

	// FBOs //
		// FBO Init
	FBO_main.f_init();
	FBO_main.f_bind();
	buffer_tex_a.f_init(iResolution);
	FBO_main.f_unbind();

	last_frame_tex.f_init(iResolution);

	glClearColor(0, 0, 0, 1);
	while (!glfwWindowShouldClose(window)) {
		if (!pause) {
			// Input Handling
			if (keys[GLFW_KEY_D]) {
				camera.f_move( 1, 0, 0, camera_move_sensitivity);
				camera_change = true;
				iFrame = 0;
			}
			if (keys[GLFW_KEY_A]) {
				camera.f_move(-1, 0, 0, camera_move_sensitivity);
				camera_change = true;
				iFrame = 0;
			}
			if (keys[GLFW_KEY_E] || keys[GLFW_KEY_SPACE]) {
				camera.f_move(0,  1, 0, camera_move_sensitivity);
				camera_change = true;
				iFrame = 0;
			}
			if (keys[GLFW_KEY_Q] || keys[GLFW_KEY_LEFT_CONTROL]) {
				camera.f_move(0, -1, 0, camera_move_sensitivity);
				camera_change = true;
				iFrame = 0;
			}
			if (keys[GLFW_KEY_W]) {
				camera.f_move(0, 0,  1, camera_move_sensitivity);
				camera_change = true;
				iFrame = 0;
			}
			if (keys[GLFW_KEY_S]) {
				camera.f_move(0, 0, -1, camera_move_sensitivity);
				camera_change = true;
				iFrame = 0;
			}

			double Time = glfwGetTime() - iTime;
			FBO_main.f_bind();
			glClear(GL_COLOR_BUFFER_BIT);
			Buffer_A.f_activate();
			VAO_main.f_bind();

			glUniform1f (glGetUniformLocation(Buffer_A.ID, "iTime"),       GLfloat(Time));
			glUniform1ui(glGetUniformLocation(Buffer_A.ID, "iFrame"),      GLuint(iFrame));
			glUniform2fv(glGetUniformLocation(Buffer_A.ID, "iResolution"), 1, value_ptr(vec2(iResolution)));

			glUniform1f (glGetUniformLocation(Buffer_A.ID, "iCameraFocalLength"), GLfloat(camera.focal_length));
			glUniform1f (glGetUniformLocation(Buffer_A.ID, "iCameraSensorWidth"), GLfloat(camera.sensor_width));
			glUniform3fv(glGetUniformLocation(Buffer_A.ID, "iCameraPos"),   1, value_ptr(vec3(camera.position)));
			glUniform3fv(glGetUniformLocation(Buffer_A.ID, "iCameraFront"), 1, value_ptr(vec3(camera.z_vector)));
			glUniform3fv(glGetUniformLocation(Buffer_A.ID, "iCameraUp"),    1, value_ptr(vec3(camera.y_vector)));
			glUniform1i (glGetUniformLocation(Buffer_A.ID, "iCameraChange"), camera_change);
			last_frame_tex.f_bind(GL_TEXTURE0);

			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

			glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, iResolution.x, iResolution.y);
			last_frame_tex.f_unbind();

			FBO_main.f_unbind();

			Main_Image.f_activate();

			glUniform1f (glGetUniformLocation(Main_Image.ID, "iTime"),       GLfloat(Time));
			glUniform1ui(glGetUniformLocation(Main_Image.ID, "iFrame"),      GLuint(iFrame));
			glUniform2fv(glGetUniformLocation(Main_Image.ID, "iResolution"), 1, value_ptr(vec2(iResolution)));
			buffer_tex_a.f_bind(GL_TEXTURE0);

			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

			iFrame++;
			camera_change = false;
		}
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
}