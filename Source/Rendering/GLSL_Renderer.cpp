#include "Rendering/GLSL_Renderer.h"

GLSL_Renderer::GLSL_Renderer() {
	renderer = Kerzenlicht_Renderer();
	display_resolution = uvec2(1920, 1080);


	camera_move_sensitivity = 0.15;
	camera_view_sensitivity = 0.075;
	keys = vector(348, false);
	last_mouse = dvec2(display_resolution) / 2.0;

	run_time = 0.0;
	last_time = 0;
	current_time = 0;
	window_time = 0.0;
	frame_time = 0.0;

	main_vao = VAO();
	main_vbo = VBO();
	main_ebo = EBO();
	raw_frame_program = Shader_Program("Display Shader");
}

void GLSL_Renderer::f_init() {
	f_initGlfw();
	f_initImGui();
	f_displayLoop();
	f_exit();
}

void GLSL_Renderer::f_exit() {
	ImGui_ImplOpenGL3_Shutdown();
	ImGui_ImplGlfw_Shutdown();
	ImGui::DestroyContext();

	glfwDestroyWindow(window);
	glfwTerminate();
}

void GLSL_Renderer::f_initGlfw() {
	glfwInit();

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	window = glfwCreateWindow(display_resolution.x, display_resolution.y, "GLSL Renderer", NULL, NULL);

	Image icon = Image();
	if (icon.f_load("./resources/Icon.png", false)) {
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
	glfwSwapInterval(1);
	gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

	glfwSetWindowUserPointer(window, this);

	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
	glfwSetCursorPosCallback(window, cursor_position_callback);
	glfwSetMouseButtonCallback(window, mouse_button_callback);
	glfwSetScrollCallback(window, scroll_callback);
	glfwSetKeyCallback(window, key_callback);
}

void GLSL_Renderer::f_initImGui() {
	IMGUI_CHECKVERSION();
	ImGui::CreateContext();
	ImGuiIO& io = ImGui::GetIO(); (void)io;
	io.FontGlobalScale = 2.25f;
	io.IniFilename = nullptr;
	//io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
	//io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

	ImGui::StyleColorsDark();
	ImGui_ImplGlfw_InitForOpenGL(window, true);
	ImGui_ImplOpenGL3_Init("#version 460");
}

void GLSL_Renderer::f_recompile() {
	raw_frame_program.f_compile();
	run_time = glfwGetTime();
}

void GLSL_Renderer::f_renderGui() {
	ImGui_ImplOpenGL3_NewFrame();
	ImGui_ImplGlfw_NewFrame();
	ImGui::NewFrame();

	ImGui::SetNextWindowPos(ImVec2(0, 0));
	ImGuiIO& io = ImGui::GetIO(); (void)io;
	ImGui::SetNextWindowSize(io.DisplaySize);
	ImGui::Begin("Fullscreen Window", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoCollapse);

	ImGui::Begin("Hello, ImGui!");
	ImGui::Text("Hello, world!");
	ImGui::End();

}

void GLSL_Renderer::f_displayLoop() {
	glViewport(0, 0, display_resolution.x, display_resolution.y);

	// Generates Shader object using shaders defualt.vert and default.frag
	raw_frame_program.f_init("./resources/Shaders/Display.glsl");
	renderer.f_updateDisplay(display_texture);

	// VERTICES //
	GLfloat vertices[16] = {
		-1.0f, -1.0f, 0.0f, 0.0f,
		 1.0f, -1.0f, 1.0f, 0.0f,
		 1.0f,  1.0f, 1.0f, 1.0f,
		-1.0f,  1.0f, 0.0f, 1.0f,
	};
	GLuint faces[6] = {
		0, 1, 2,
		2, 3, 0
	};
	// VAO Bind
	main_vao.f_init();
	main_vao.f_bind();
	// VBO Init
	main_vbo.f_init(vertices, 16 * sizeof(float));
	// EBO Init
	main_ebo.f_init(faces, 6 * sizeof(float));
	// VAO Link
	main_vao.f_linkVBO(main_vbo, 0, 2, GL_FLOAT, 4 * sizeof(GLfloat), (void*)0);
	main_vao.f_linkVBO(main_vbo, 1, 2, GL_FLOAT, 4 * sizeof(GLuint), (void*)(2 * sizeof(GLfloat)));

	main_vao.f_unbind();
	main_vbo.f_unbind();
	main_ebo.f_unbind();

	glClearColor(0, 0, 0, 1);
	main_vao.f_bind();
	raw_frame_program.f_activate();

	while (!glfwWindowShouldClose(window)) {
		glfwPollEvents();
		if (keys[GLFW_KEY_D]) {
			renderer.file.render_camera.f_move(1, 0, 0, camera_move_sensitivity);
		}
		if (keys[GLFW_KEY_A]) {
			renderer.file.render_camera.f_move(-1, 0, 0, camera_move_sensitivity);
		}
		if (keys[GLFW_KEY_E] || keys[GLFW_KEY_SPACE]) {
			renderer.file.render_camera.f_move(0, 1, 0, camera_move_sensitivity);
		}
		if (keys[GLFW_KEY_Q] || keys[GLFW_KEY_LEFT_CONTROL]) {
			renderer.file.render_camera.f_move(0, -1, 0, camera_move_sensitivity);
		}
		if (keys[GLFW_KEY_W]) {
			renderer.file.render_camera.f_move(0, 0, 1, camera_move_sensitivity);
		}
		if (keys[GLFW_KEY_S]) {
			renderer.file.render_camera.f_move(0, 0, -1, camera_move_sensitivity);
		}

		glClear(GL_COLOR_BUFFER_BIT);

		#if DISPLAY_GUI
			f_renderGui();
		#endif

		renderer.f_render();
		renderer.f_updateDisplay(display_texture);

		current_time = clock();
		frame_time = (double)(current_time - last_time) / 1000.0;
		last_time = current_time;
		run_time += frame_time;
		window_time += frame_time;

		renderer.f_bindDisplay(display_texture, raw_frame_program.ID);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

		if (window_time > 0.2) {
			window_time -= 0.2;
			Lace title;
			title << "KerzenLicht | " << 1.0 / frame_time << " Fps";
			glfwSetWindowTitle(window, title.str().c_str());
		}

		#if DISPLAY_GUI
			ImGui::Render();
			ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
		#endif
		glfwSwapBuffers(window);
	}
}

void GLSL_Renderer::framebuffer_size_callback(GLFWwindow* window, int width, int height) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
	glViewport(0, 0, width, height);
	instance->display_resolution = uvec2(width, height);
	instance->run_time = glfwGetTime();
}

void GLSL_Renderer::cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
	if (instance->keys[GLFW_MOUSE_BUTTON_RIGHT]) {
		double xoffset = xpos - instance->last_mouse.x;
		double yoffset = instance->last_mouse.y - ypos;

		instance->last_mouse = dvec2(xpos, ypos);

		instance->renderer.file.render_camera.f_rotate(val(xoffset * instance->camera_view_sensitivity), val(yoffset * instance->camera_view_sensitivity));
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
		instance->camera_move_sensitivity /= 1.1;
	}
	if (yoffset > 0) {
		instance->camera_move_sensitivity *= 1.1;
	}
}

void GLSL_Renderer::key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	GLSL_Renderer* instance = static_cast<GLSL_Renderer*>(glfwGetWindowUserPointer(window));
	// Input Handling
	if (key == GLFW_KEY_R && action == GLFW_PRESS) {
		instance->f_recompile();
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