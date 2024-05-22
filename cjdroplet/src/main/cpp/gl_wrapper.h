/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 * Description: Droplet for Cangjie API
 */

#ifndef gl_wrapper_h
#define gl_wrapper_h

#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <cmath>
#include <unistd.h>
#include <pthread.h>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <GLES3/gl32.h>

#include "shader_str.h"

#define RED "\033[31m"    /* Red */
#define GREEN "\033[32m"  /* Green */
#define YELLOW "\033[33m" /* Yellow */
#define BLUE "\033[34m"   /* Blue */
#define CYAN "\033[36m"   /* Cyan */
#define WHITE "\033[37m"  /* White */
#define RESET "\033[0m"
#define MAGENTA "\033[35m" /* Magenta */
#define BLACK "\033[30m"   /* Black */

#define glerr \
GLenum er = glGetError(); \
if (er) { \
    printf("glerror %s: %d\n", __func__, er); \
}

const GLuint tfProcError = 1;
const GLuint tfTexError = 2;

const GLuint brightIdx = 0;
const GLuint contrastIdx = 1;
const GLuint grayscaleIdx = 2;
const GLuint invertIdx = 3;
const GLuint kuwaharaIdx = 4;
const GLuint pixelationIdx = 5;
const GLuint sepiaIdx = 6;
const GLuint sketchIdx = 7;
const GLuint swirlIdx = 8;
const GLuint toonIdx = 9;
const GLuint vignetteIdx = 10;
const GLuint fitcenterIdx = 11;
const GLuint centerinsideIdx = 12;
const GLuint centercropIdx = 13;
const GLuint circlecropIdx = 14;
const GLuint roundedcornersIdx = 15;
const GLuint rotateIdx = 16;
const GLuint fastblurIdx = 17;
const GLuint IdxNum = 18;


// t, w, h, c, 7
const GLuint GLENV_PARAM_MAX_NUM = 14;

typedef struct {
    bool isInit;
    EGLDisplay display;
    EGLint major;
    EGLint minor;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;
    int glVersion;
    int wSurf;
    int hSurf;
    GLuint progIds[IdxNum];
}TFEnv;

extern "C" GLuint getBrightIdx();
extern "C" GLuint getContrastIdx();
extern "C" GLuint getGrayscaleIdx();
extern "C" GLuint getInvertIdx();
extern "C" GLuint getKuwaharaIdx();
extern "C" GLuint getPixelationIdx();
extern "C" GLuint getSepiaIdx();
extern "C" GLuint getSketchIdx();
extern "C" GLuint getSwirlIdx();
extern "C" GLuint getToonIdx();
extern "C" GLuint getVignetteIdx();
extern "C" GLuint getFitcenterIdx();
extern "C" GLuint getCenterinsideIdx();
extern "C" GLuint getCentercropIdx();
extern "C" GLuint getCirclecropIdx();
extern "C" GLuint getRoundedcornersIdx();
extern "C" GLuint getRotateIdx();
extern "C" GLuint getFastBlurIdx();
extern "C" GLuint getIdxNum();

extern "C" void tfInit();
extern "C" void tfRelease();
extern "C" void tfReleaseSurface();
extern "C" void tfReleaseContext();
extern "C" void tfReleaseDisplay();
extern "C" void tfGenSurface(int w, int h);
extern "C" GLuint tfDoShader(const char* shaderStr, int type);
extern "C" GLuint tfDoProgram(const char* vs, const char* fs);
extern "C" void tfInitPrograms();
extern "C" void tfLoadTextureRGBA(GLuint tex, GLubyte* data, GLsizei w, GLsizei h);

extern "C" unsigned int brightnessFilter();
extern "C" unsigned int tfProc();

extern "C" unsigned int getThreadId();
extern "C" unsigned int setTask(unsigned int a);
extern "C" unsigned long int startThread();
extern "C" void stopThread();

extern "C" unsigned int tfTask(uint8_t* pOut,
                               uint8_t* pIn,
                               float* pparam);

#endif