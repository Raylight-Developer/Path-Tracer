#include "Rendering/Opengl/Shader_Program.h"

void Shader_Program::f_init(const char* i_fragmentFile) {
	frag_source = i_fragmentFile;
	f_compile();
}

void Shader_Program::f_compile() {
	glDeleteProgram(ID);

	string vertexCode = f_loadFromFile("./resources/Shaders/Vert.glsl");
	string fragmentCode = f_loadFromFile(frag_source);

	const char* vertexSource = vertexCode.c_str();
	const char* fragmentSource = fragmentCode.c_str();

	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShader, 1, &vertexSource, NULL);
	glCompileShader(vertexShader);
	f_checkCompilation(vertexShader, "VERTEX " + program_name);

	GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragmentShader, 1, &fragmentSource, NULL);
	glCompileShader(fragmentShader);
	f_checkCompilation(fragmentShader, "FRAGMENT " + program_name);

	ID = glCreateProgram();
	glAttachShader(ID, vertexShader);
	glAttachShader(ID, fragmentShader);
	glLinkProgram(ID);
	f_checkCompilation(ID, "PROGRAM " + program_name);

	glDeleteShader(vertexShader);
	glDeleteShader(fragmentShader);
}

string Shader_Program::f_loadFromFile(const string& i_filename) {
	ifstream in(i_filename, ios::binary);
	if (in) {
		string contents;
		in.seekg(0, ios::end);
		contents.resize(in.tellg());
		in.seekg(0, ios::beg);
		in.read(&contents[0], contents.size());
		in.close();
		return(contents);
	}
	throw(errno);
}

void Shader_Program::f_activate() {
	glUseProgram(ID);
}

void Shader_Program::f_delete() {
	glDeleteProgram(ID);
}

void Shader_Program::f_checkCompilation(const GLuint& i_shader, const string& i_shader_name) {
	GLint hasCompiled;
	char infoLog[1024];
	if (i_shader_name != "PROGRAM") {
		glGetShaderiv(i_shader, GL_COMPILE_STATUS, &hasCompiled);
		if (hasCompiled == GL_FALSE) {
			glGetShaderInfoLog(i_shader, 1024, NULL, infoLog);
			cout << "SHADER_COMPILATION_ERROR for:" << i_shader_name << "\n" << infoLog << endl;
		}
	}
	else {
		glGetProgramiv(i_shader, GL_LINK_STATUS, &hasCompiled);
		if (hasCompiled == GL_FALSE) {
			glGetProgramInfoLog(i_shader, 1024, NULL, infoLog);
			cout << "SHADER_LINKING_ERROR for:" << i_shader_name << "\n" << infoLog << endl;
		}
	}
}