//
//  OpenGLES.m
//  OpenCV-3D
//
//  Created by Okaylens-Ares on 10/05/2017.
//  Copyright © 2017 Okaylens-Ares. All rights reserved.
//

#import "OpenGLES.h"
#include <vector>

static GLubyte shaderText[MAX_SHADER_LENGTH];

OpenGLES::OpenGLES(float uScreenWidth,float uScreenHeight){
    
    screenWidth=uScreenWidth;
    screenHeight=uScreenHeight;
}

void OpenGLES::setupOpenGL(){
    
    //load the shaders, compile them and link them
    
    loadShaders("Shader.vsh", "Shader.fsh");
    
    glEnable(GL_DEPTH_TEST);
    
    //1. Generate a Vertex Array Object
    
    glGenVertexArraysOES(1,&vertexArrayObject);
    
    //2. Bind the Vertex Array Object
    
    glBindVertexArrayOES(vertexArrayObject);
    
    //3. Generate a Vertex Buffer Object
    
    glGenBuffers(1, &vertexBufferObject);
    
    //4. Bind the Vertex Buffer Object
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    
    //5. Dump the data into the Buffer
    /* Read "Loading data into OpenGL Buffers" if not familiar with loading data
     using glBufferSubData.
     http://www.www.haroldserrano.com/blog/loading-vertex-normal-and-uv-data-onto-opengl-buffers
     */
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(robot_vertices)+sizeof(robot_normal), NULL, GL_STATIC_DRAW);
    
    //5a. Load data with glBufferSubData
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(robot_vertices), robot_vertices);
    
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(robot_vertices), sizeof(robot_normal), robot_normal);
    
    //6. Get the location of the shader attribute called "position"
    
    positionLocation=glGetAttribLocation(programObject, "position");
    
    //7. Get the location of the shader attribute called "normal"
    
    normalLocation=glGetAttribLocation(programObject, "normal");
    
    //8. Get Location of uniforms
    modelViewProjectionUniformLocation = glGetUniformLocation(programObject,"modelViewProjectionMatrix");
    
    normalMatrixUniformLocation = glGetUniformLocation(programObject,"normalMatrix");
    
    
    //9. Enable both attribute locations
    
    glEnableVertexAttribArray(positionLocation);
    
    glEnableVertexAttribArray(normalLocation);
    
    //10. Link the buffer data to the shader attribute locations
    
    glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid *) 0);
    
    glVertexAttribPointer(normalLocation, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)sizeof(robot_vertices));
    
    
    /*Since we are going to start the rendering process by using glDrawElements
     We are going to create a buffer for the indices. Read "Starting the rendering process in OpenGL"
     if not familiar. http://www.www.haroldserrano.com/blog/starting-the-primitive-rendering-process-in-opengl */
    
    //11. Create a new buffer for the indices
    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
    
    //12. Bind the new buffer to binding point GL_ELEMENT_ARRAY_BUFFER
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    
    //13. Load the buffer with the indices found in robot_index array
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(robot_index), robot_index, GL_STATIC_DRAW);
    
    //14. Unbind the VAO
    glBindVertexArrayOES(0);
    
    //Sets the transformation
    setTransformation();
    
}

void Character::draw(){
    
    //1. Set the shader program
    glUseProgram(programObject);
    
    //2. Bind the VAO
    glBindVertexArrayOES(vertexArrayObject);
    
    //3. Start the rendering process
    glDrawElements(GL_TRIANGLES, sizeof(robot_index)/4, GL_UNSIGNED_INT,(void*)0);
    
    //4. Disable the VAO
    glBindVertexArrayOES(0);
    
}

void Character::setTransformation(){
    
    //1. Set up the model space
    modelSpace=GLKMatrix4Identity;
    
    //Since we are importing the model from Blender, we need to change the axis of the model
    //else the model will not show properly. x-axis is left-right, y-axis is coming out the screen, z-axis is up and
    //down
    
    GLKMatrix4 blenderSpace=GLKMatrix4MakeAndTranspose(1,0,0,0,
                                                       0,0,1,0,
                                                       0,-1,0,0,
                                                       0,0,0,1);
    
    //2. Transform the model space by Blender Space
    modelSpace=GLKMatrix4Multiply(blenderSpace, modelSpace);
    
    //3. Set up the world space
    worldSpace=GLKMatrix4Identity;
    
    //4. Transform the model space to the world space
    modelWorldSpace=GLKMatrix4Multiply(worldSpace,modelSpace);
    
    //5. Set up the view space. We are translating the view space 1 unit down and 5 units out of the screen.
    cameraViewSpace = GLKMatrix4MakeTranslation(0.0f, -1.0f, -8.0f);
    
    //6. Transform the model-World Space by the View space
    modelWorldViewSpace = GLKMatrix4Multiply(cameraViewSpace, modelWorldSpace);
    
    
    //7. set the Projection-Perspective space with a 45 degree field of view and an aspect ratio
    //of width/heigh. The near a far clipping planes are set to 0.1 and 100.0 respectively
    projectionSpace = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), fabsf(screenWidth/screenHeight), 0.1f, 100.0f);
    
    
    //8. Transform the model-world-view space to the projection space
    modelWorldViewProjectionSpace = GLKMatrix4Multiply(projectionSpace, modelWorldViewSpace);
    
    //9. extract the 3x3 normal matrix from the model-world-view space for shading(light) purposes
    normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelWorldViewSpace), NULL);
    
    
    //10. Assign the model-world-view-projection matrix data to the uniform location:modelviewProjectionUniformLocation
    glUniformMatrix4fv(modelViewProjectionUniformLocation, 1, 0, modelWorldViewProjectionSpace.m);
    
    //11. Assign the normalMatrix data to the uniform location:normalMatrixUniformLocation
    glUniformMatrix3fv(normalMatrixUniformLocation, 1, 0, normalMatrix.m);
    
    
}


void Character::loadShaders(const char* uVertexShaderProgram, const char* uFragmentShaderProgram){
    
    // Temporary Shader objects
    GLuint VertexShader;
    GLuint FragmentShader;
    
    //1. Create shader objects
    VertexShader = glCreateShader(GL_VERTEX_SHADER);
    FragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    
    //load the shaders files. Usually you want to check the return value of this function, if
    //it returns true, then the shaders were found, else there was an error, but for simplicity,
    //I wont check for those errors here
    
    //2. Load the shaders file
    loadShaderFile(uVertexShaderProgram, VertexShader);
    loadShaderFile(uFragmentShaderProgram, FragmentShader);
    
    //3. Compile them
    glCompileShader(VertexShader);
    glCompileShader(FragmentShader);
    
    //4. Create the program object
    programObject = glCreateProgram();
    
    //5. Attach the shaders to the program
    glAttachShader(programObject, VertexShader);
    glAttachShader(programObject, FragmentShader);
    
    //6. Link them to the program object
    glLinkProgram(programObject);
    
    // These are no longer needed
    glDeleteShader(VertexShader);
    glDeleteShader(FragmentShader);
    
    //7. Use the program
    glUseProgram(programObject);
}


void Character::update(){
    
}

#pragma mark - Load, compile and link shaders to program

bool Character::loadShaderFile(const char *szFile, GLuint shader)
{
    GLint shaderLength = 0;
    FILE *fp;
    
    // Open the shader file
    fp = fopen(szFile, "r");
    if(fp != NULL)
    {
        // See how long the file is
        while (fgetc(fp) != EOF)
            shaderLength++;
        
        // Allocate a block of memory to send in the shader
        //assert(shaderLength < MAX_SHADER_LENGTH);   // make me bigger!
        if(shaderLength > MAX_SHADER_LENGTH)
        {
            fclose(fp);
            return false;
        }
        
        // Go back to beginning of file
        rewind(fp);
        
        // Read the whole file in
        if (shaderText != NULL)
            fread(shaderText, 1, shaderLength, fp);
        
        // Make sure it is null terminated and close the file
        shaderText[shaderLength] = '\0';
        fclose(fp);
    }
    else
        return false;
    
    // Load the string
    loadShaderSrc((const char *)shaderText, shader);
    
    return true;
}

// Load the shader from the source text
void Character::loadShaderSrc(const char *szShaderSrc, GLuint shader)
{
    GLchar *fsStringPtr[1];
    
    fsStringPtr[0] = (GLchar *)szShaderSrc;
    glShaderSource(shader, 1, (const GLchar **)fsStringPtr, NULL);
}

#pragma mark - Tear down of OpenGL
void Character::teadDownOpenGL(){
    
    glDeleteBuffers(1, &vertexBufferObject);
    glDeleteVertexArraysOES(1, &vertexArrayObject);
    
    
    if (programObject) {
        glDeleteProgram(programObject);
        programObject = 0;
        
    }
    
}

@end
