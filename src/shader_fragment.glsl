#version 330 core

// Atributos de fragmentos recebidos como entrada ("in") pelo Fragment Shader.
// Neste exemplo, este atributo foi gerado pelo rasterizador como a
// interpolação da posição global e a normal de cada vértice, definidas em
// "shader_vertex.glsl" e "main.cpp".
in vec4 position_world;
in vec4 normal;

// Posição do vértice atual no sistema de coordenadas local do modelo.
in vec4 position_model;

// Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
in vec2 texcoords;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Identificador que define qual objeto está sendo desenhado no momento
//#define SPHERE 0
#define SKY_BOX  0
#define PLAYER  1
#define PLANE  2
uniform int object_id;

// Parâmetros da axis-aligned bounding box (AABB) do modelo
uniform vec4 bbox_min;
uniform vec4 bbox_max;

// Variáveis para acesso das imagens de textura
uniform sampler2D TextureImage0;
uniform sampler2D TextureImage1;
uniform sampler2D TextureImage2;
uniform sampler2D TextureImage3;
uniform sampler2D TextureImage4;

// O valor de saída ("out") de um Fragment Shader é a cor final do fragmento.
out vec3 color;

// Constantes
#define M_PI   3.14159265358979323846
#define M_PI_2 1.57079632679489661923

void main()
{
    // Obtemos a posição da câmera utilizando a inversa da matriz que define o
    // sistema de coordenadas da câmera.
    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    // O fragmento atual é coberto por um ponto que percente à superfície de um
    // dos objetos virtuais da cena. Este ponto, p, possui uma posição no
    // sistema de coordenadas global (World coordinates). Esta posição é obtida
    // através da interpolação, feita pelo rasterizador, da posição de cada
    // vértice.
    vec4 p = position_world;

    // Normal do fragmento atual, interpolada pelo rasterizador a partir das
    // normais de cada vértice.
    vec4 n = normalize(normal);

    // Vetor que define o sentido da fonte de luz em relação ao ponto atual.
  //  vec4 l = normalize(vec4(1.0,1.0,0.0,0.0));

    vec4 light_pos = vec4(0.0f,10.0f,0.0f,1.0f);

    // Vetor que define o sentido da fonte de luz em relação ao ponto atual.
    vec4 l = normalize(light_pos - p);

    // Vetor que define o sentido da câmera em relação ao ponto atual.
    vec4 v = normalize(camera_position - p);

    // Vetor que define o sentido da reflexão especular ideal.
    vec4 r = -l + 2*n*dot(n,l);

    // Parâmetros que definem as propriedades espectrais da superfície
    vec3 Kd; // Refletância difusa que será obtida da imagem de textura
    vec3 Ks; // Refletância especular
    vec3 Ka; // Refletância ambiente
    float q; // Expoente especular para o modelo de iluminação de Phong

    // Coordenadas de textura U e V
    float U = 0.0;
    float V = 0.0;

    if ( object_id == SKY_BOX )
    {

        vec4 p_lin = camera_position + ((position_world - camera_position)/length(position_world - camera_position));
        vec4 coord_vector = (p_lin - camera_position);
        float theta = atan(coord_vector.x,coord_vector.z);
        float phi = asin(coord_vector.y);

        U = (theta + M_PI)/(2*M_PI);
        V = (phi + M_PI_2)/M_PI;

        //Kd = texture(TextureImage3, vec2(U,V)).rgb;

        // Propriedades espectrais da superfície
        Kd = vec3(1.0,0.0,0.03); // Refletância difusa
        Ks = vec3(0.8,0.7,0.7); // Refletância especular
        Ka = vec3(0.3,0.2,0.2); // Refletância ambiente
        q = 10.0;    //Expoente para o modelo de Phong

        //inverte a normal da esfera, para que ela esteja "virada para dentro"
        n = -n;
    }

    else if ( object_id == PLAYER )
    {
        // PREENCHA AQUI as coordenadas de textura do coelho, computadas com
        // projeção planar XY em COORDENADAS DO MODELO. Utilize como referência
        // o slides 99-104 do documento Aula_20_Mapeamento_de_Texturas.pdf,
        // e também use as variáveis min*/max* definidas abaixo para normalizar
        // as coordenadas de textura U e V dentro do intervalo [0,1]. Para
        // tanto, veja por exemplo o mapeamento da variável 'p_v' utilizando
        // 'h' no slides 158-160 do documento Aula_20_Mapeamento_de_Texturas.pdf.
        // Veja também a Questão 4 do Questionário 4 no Moodle.

        float minx = bbox_min.x;
        float maxx = bbox_max.x;

        float miny = bbox_min.y;
        float maxy = bbox_max.y;

        float minz = bbox_min.z;
        float maxz = bbox_max.z;

        U = (position_model.x - minx)/(maxx-minx);
        V = (position_model.y - miny)/(maxy-miny);
    }
    else if ( object_id == PLANE )
    {
        // Coordenadas de textura do plano, obtidas do arquivo OBJ.
        U = texcoords.x;
        V = texcoords.y;
    }

    // Obtemos a refletância difusa a partir da leitura da imagem TextureImage0
    vec3 Kd0 = texture(TextureImage0, vec2(U,V)).rgb;
    vec3 Kd1 = texture(TextureImage4, vec2(U,V)).rgb;
    vec3 Kd2 = texture(TextureImage3, vec2(U,V)).rgb;

    // Espectro da fonte de iluminação
    vec3 light_spectrum = vec3(1.0,1.0,1.0);

    // Espectro da luz ambiente
    vec3 ambient_light_spectrum = vec3(0.6,0.6,0.6);

    // Equação de Iluminação
    float lambert = max(0,dot(n,l));

    // Termo para iluminacao de Phong
    float phong_specular_term = pow(float(max(0.0f,dot(r,v))),q);

    //textura e iluminação para cada objetos
    if ( object_id == SKY_BOX )
    {
      /*  color = Kd2 * light_spectrum * lambert //Termo difuso (Lambert)
                + Ka * ambient_light_spectrum   //Fator Ambiente
                + Ks * light_spectrum * phong_specular_term; */
        
        color = Kd2 * light_spectrum * lambert;
    }

    else if ( object_id == PLAYER )
    {
        color = Kd0 * light_spectrum * lambert;
    }

    else if ( object_id == PLANE )
    {
        color = Kd1 * ambient_light_spectrum;
    }

    //  color = Kd0 * (pow(lambert, 1) + 0.01) + Kd1 * (1 - (pow(lambert, 0.2)) + 0.01);
    // Cor final com correção gamma, considerando monitor sRGB.
    // Veja https://en.wikipedia.org/w/index.php?title=Gamma_correction&oldid=751281772#Windows.2C_Mac.2C_sRGB_and_TV.2Fvideo_standard_gammas
    color = pow(color, vec3(1.0,1.0,1.0)/2.2);

    // Cor final com correção gamma, considerando monitor sRGB.
    // Veja https://en.wikipedia.org/w/index.php?title=Gamma_correction&oldid=751281772#Windows.2C_Mac.2C_sRGB_and_TV.2Fvideo_standard_gammas
    color = pow(color, vec3(1.0,1.0,1.0)/2.2);
}
