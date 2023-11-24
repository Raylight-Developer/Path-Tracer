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

	renderer = Kerzenlicht_Renderer();

	iTime = 0.0;
	iFrame = 0;
	iBidirectional = true;
	iCameraChange = false;

	camera = Camera();

	render_mode = Render_Mode::PATHTRACED;
	camera_move_sensitivity = 0.15;
	camera_view_sensitivity = 0.075;
	keys = vector(348, false);
	last_mouse = dvec2(renderer.resolution) / 2.0;

	last_time = 0;
	current_time = 0;
	window_time = 0.0;
	frame_time = 0.0;

	main_vao         = VAO();
	main_vbo         = VBO();
	main_ebo         = EBO();
	raw_frame_program      = Shader_Program("Raw Image");
}

void GLSL_Renderer::f_recompile() {
	raw_frame_program.f_compile();

	//camera = Camera();
	iCameraChange = true;
	iFrame = 0;
	iTime = glfwGetTime();
}

void GLSL_Renderer::framebuffer_size_callback(GLFWwindow* window, int width, int height) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
	glViewport(0, 0, width, height);
	instance->renderer.resolution.x = width;
	instance->renderer.resolution.y = height;
	instance->iFrame = 0;
	instance->iTime = glfwGetTime();
}

void GLSL_Renderer::cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
	if (instance->keys[GLFW_MOUSE_BUTTON_RIGHT]) {
		double xoffset = xpos - instance->last_mouse.x;
		double yoffset = instance->last_mouse.y - ypos;

		instance->last_mouse = dvec2(xpos, ypos);

		instance->camera.f_rotate(xoffset * instance->camera_view_sensitivity, yoffset * instance->camera_view_sensitivity);
		instance->iCameraChange = true;
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
		instance->iCameraChange = true;
		instance->iFrame = 0;
		instance->camera_move_sensitivity /= 1.1;
	}
	if (yoffset > 0) {
		instance->iCameraChange = true;
		instance->iFrame = 0;
		instance->camera_move_sensitivity *= 1.1;
	}
}

void GLSL_Renderer::key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
	// Input Handling
	if (key == GLFW_KEY_R && action == GLFW_PRESS) {
		instance->f_recompile();
	}
	if (key == GLFW_KEY_V && action == GLFW_PRESS) {
		instance->render_mode = switchRenderMode(instance->render_mode);
		instance->iCameraChange = true;
		instance->iFrame = 0;
	}
	if (key == GLFW_KEY_C && action == GLFW_PRESS) {
		instance->camera = Camera();
		instance->iCameraChange = true;
		instance->iFrame = 0;
	}
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, GLFW_TRUE);
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

	GLFWwindow* window = glfwCreateWindow(renderer.resolution.x, renderer.resolution.y, "GLSL Renderer", NULL, NULL);
	
	Image icon = Image();
	if (icon.f_load("./resources/Icon.png")) {
		GLFWimage image_icon;
		image_icon.width = icon.width;
		image_icon.height = icon.height;
		image_icon.pixels = icon.data;
		glfwSetWindowIcon(window, 1, &image_icon);
	}

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

	glViewport(0, 0, renderer.resolution.x , renderer.resolution.y);

	// Generates Shader object using shaders defualt.vert and default.frag
	raw_frame_program.f_init("./resources/Shaders/RawFrame.glsl");
	renderer.f_updateDisplay(display_texture);

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

	Texture background_tex = Texture();
	background_tex.f_init("D:/UVG/Path-Tracer/resources/Texture.png");

	glClearColor(0, 0, 0, 1);
	while (!glfwWindowShouldClose(window)) {
		if (keys[GLFW_KEY_D]) {
			camera.f_move(1, 0, 0, camera_move_sensitivity);
			iCameraChange = true;
			iFrame = 0;
		}
		if (keys[GLFW_KEY_A]) {
			camera.f_move(-1, 0, 0, camera_move_sensitivity);
			iCameraChange = true;
			iFrame = 0;
		}
		if (keys[GLFW_KEY_E] || keys[GLFW_KEY_SPACE]) {
			camera.f_move(0, 1, 0, camera_move_sensitivity);
			iCameraChange = true;
			iFrame = 0;
		}
		if (keys[GLFW_KEY_Q] || keys[GLFW_KEY_LEFT_CONTROL]) {
			camera.f_move(0, -1, 0, camera_move_sensitivity);
			iCameraChange = true;
			iFrame = 0;
		}
		if (keys[GLFW_KEY_W]) {
			camera.f_move(0, 0, 1, camera_move_sensitivity);
			iCameraChange = true;
			iFrame = 0;
		}
		if (keys[GLFW_KEY_S]) {
			camera.f_move(0, 0, -1, camera_move_sensitivity);
			iCameraChange = true;
			iFrame = 0;
		}
		current_time = clock();
		frame_time = float(current_time - last_time) / CLOCKS_PER_SEC;
		last_time = current_time;
		iTime += frame_time;
		window_time += frame_time;

		main_vao.f_bind();
		glClear(GL_COLOR_BUFFER_BIT);
		raw_frame_program.f_activate();


		renderer.f_bindDisplay(display_texture, raw_frame_program.ID);
		//background_tex.f_bind(GL_TEXTURE0);
		//glUniform1i (glGetUniformLocation(raw_frame_program.ID, "render_output"), 0);

		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

		iFrame++;
		iCameraChange = false;

		if (window_time > 5.0) {
			window_time -= 5.0;
			Lace title;
			title << "KerzenLicht | " << 1.0 / frame_time << " Fps";
			glfwSetWindowTitle(window, title.cstr());
		}

		glfwSwapBuffers(window);
		glfwPollEvents();
	}
	f_exit();
}

void GLSL_Renderer::f_exit() {
	glfwTerminate();
}