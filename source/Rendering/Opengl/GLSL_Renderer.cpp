#include "Rendering/Opengl/GLSL_Renderer.h"

GLSL_Renderer::GLSL_Renderer() {
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

	last_frame_time = 0;
	frame_time = 0.01;

	main_vao       = VAO();
	main_vbo       = VBO();
	main_ebo          = EBO();
	buffer_tex_a   = FBT();
	last_frame_tex = FBT();
	main_fbo       = FBO();
	main_buffer   = Shader_Program("Buffer A");
	post_buffer = Shader_Program("Main Image");

	pause = false;
}

void GLSL_Renderer::recompile() {
	main_buffer.f_compile();
	post_buffer.f_compile();

	main_fbo.f_bind();
	buffer_tex_a.f_resize(iResolution);
	main_fbo.f_unbind();
	last_frame_tex.f_resize(iResolution);

	//camera = Camera();
	camera_change = true;
	iFrame = 0;
	iTime = glfwGetTime();
}

void GLSL_Renderer::framebuffer_size_callback(GLFWwindow* window, int width, int height) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
	glViewport(0, 0, width, height);
	instance->iResolution.x = width;
	instance->iResolution.y = height;
	instance->iFrame = 0;
	instance->iTime = glfwGetTime();

	instance->main_fbo.f_bind();
	instance->buffer_tex_a.f_resize(uvec2(width, height));
	instance->main_fbo.f_unbind();
	instance->last_frame_tex.f_resize(uvec2(width, height));
}

void GLSL_Renderer::cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
	if (instance->keys[GLFW_MOUSE_BUTTON_RIGHT]) {
		double xoffset = xpos - instance->last_mouse.x;
		double yoffset = instance->last_mouse.y - ypos;

		instance->last_mouse = dvec2(xpos, ypos);

		instance->camera.f_rotate(xoffset * instance->camera_view_sensitivity, yoffset * instance->camera_view_sensitivity);
		instance->camera_change = true;
		instance->iFrame = 0;
	}
}

void GLSL_Renderer::mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
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

void GLSL_Renderer::scroll_callback(GLFWwindow* window, double xoffset, double yoffset) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
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

void GLSL_Renderer::key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
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

void GLSL_Renderer::f_init() {
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
	main_buffer.f_init("./resources/Shaders/Buffer_A.glsl");
	post_buffer.f_init("./resources/Shaders/Main_Image.glsl");

	// VERTICES //
		// VAO Bind
	main_vao.f_init();
	main_vao.f_bind();
		// VBO Init
	main_vbo.f_init(vertices.data(), vertices.size() * sizeof(float));
		// EBO Init
	main_ebo.f_init(faces.data(), faces.size() * sizeof(float));
		// VAO Link
	main_vao.f_linkVBO(main_vbo, 0, 2, GL_FLOAT, 4 * sizeof(GLfloat), (void*)0);
	main_vao.f_linkVBO(main_vbo, 1, 2, GL_FLOAT, 4 * sizeof(GLfloat), (void*)(2 * sizeof(float)));

	main_vao.f_unbind();
	main_vbo.f_unbind();
	main_ebo.f_unbind();

	// FBOs //
		// FBO Init
	main_fbo.f_init();
	main_fbo.f_bind();
	buffer_tex_a.f_init(iResolution);
	main_fbo.f_unbind();

	last_frame_tex.f_init(iResolution);

	Texture background_tex = Texture();
	//background_tex.f_init("D:/UVG/Path-Tracer/resources/Background.exr", File_Extension::EXR);

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
			frame_time = glfwGetTime() - last_frame_time;


			main_fbo.f_bind();
			glClear(GL_COLOR_BUFFER_BIT);
			main_buffer.f_activate();
			main_vao.f_bind();

			glUniform1f (glGetUniformLocation(main_buffer.ID, "iTime"),       GLfloat(Time));
			glUniform1ui(glGetUniformLocation(main_buffer.ID, "iFrame"),      GLuint(iFrame));
			glUniform2fv(glGetUniformLocation(main_buffer.ID, "iResolution"), 1, value_ptr(vec2(iResolution)));

			glUniform1f (glGetUniformLocation(main_buffer.ID, "iCameraFocalLength"), GLfloat(camera.focal_length));
			glUniform1f (glGetUniformLocation(main_buffer.ID, "iCameraSensorWidth"), GLfloat(camera.sensor_width));
			glUniform3fv(glGetUniformLocation(main_buffer.ID, "iCameraPos"),   1, value_ptr(vec3(camera.position)));
			glUniform3fv(glGetUniformLocation(main_buffer.ID, "iCameraFront"), 1, value_ptr(vec3(camera.z_vector)));
			glUniform3fv(glGetUniformLocation(main_buffer.ID, "iCameraUp"),    1, value_ptr(vec3(camera.y_vector)));
			glUniform1i (glGetUniformLocation(main_buffer.ID, "iCameraChange"), camera_change);
			//background_tex.f_bind(GL_TEXTURE1);
			//glUniform1i (glGetUniformLocation(main_buffer.ID, "iHdri"), 0);
			last_frame_tex.f_bind(GL_TEXTURE0);

			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

			glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, iResolution.x, iResolution.y);
			last_frame_tex.f_unbind();

			main_fbo.f_unbind();

			post_buffer.f_activate();

			glUniform1f (glGetUniformLocation(post_buffer.ID, "iTime"),       GLfloat(Time));
			glUniform1ui(glGetUniformLocation(post_buffer.ID, "iFrame"),      GLuint(iFrame));
			glUniform2fv(glGetUniformLocation(post_buffer.ID, "iResolution"), 1, value_ptr(vec2(iResolution)));
			buffer_tex_a.f_bind(GL_TEXTURE0);

			glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

			iFrame++;
			camera_change = false;
		}
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
}