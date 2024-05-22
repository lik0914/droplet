/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 * Description: Droplet for Cangjie API
 */

#include "gl_wrapper.h"
#include <string>

GLuint getBrightIdx()
{
    return brightIdx;
}

GLuint getContrastIdx()
{
    return contrastIdx;
}

GLuint getGrayscaleIdx()
{
    return grayscaleIdx;
}

GLuint getInvertIdx()
{
    return invertIdx;
}

GLuint getKuwaharaIdx()
{
    return kuwaharaIdx;
}

GLuint getPixelationIdx()
{
    return pixelationIdx;
}

GLuint getSepiaIdx()
{
    return sepiaIdx;
}

GLuint getSketchIdx()
{
    return sketchIdx;
}

GLuint getSwirlIdx()
{
    return swirlIdx;
}

GLuint getToonIdx()
{
    return toonIdx;
}

GLuint getVignetteIdx()
{
    return vignetteIdx;
}

GLuint getFitcenterIdx()
{
    return fitcenterIdx;
}

GLuint getCenterinsideIdx()
{
    return centerinsideIdx;
}

GLuint getCentercropIdx()
{
    return centercropIdx;
}

GLuint getCirclecropIdx()
{
    return circlecropIdx;
}

GLuint getRoundedcornersIdx()
{
    return roundedcornersIdx;
}

GLuint getRotateIdx()
{
    return rotateIdx;
}

GLuint getFastBlurIdx()
{
    return fastblurIdx;
}

GLuint getIdxNum()
{
    return IdxNum;
}


static TFEnv tfEnv = {false, NULL, 0, 0, NULL, NULL, NULL, 0, 0, 0, {0}};

const static GLfloat defaultVertexData[] = {
    -1.0f, -1.0f, 0.0f, 1.0f,
    1.0f, -1.0f, 0.0f, 1.0f,
    -1.0f, 1.0f, 0.0f, 1.0f,
    1.0f, 1.0f, 0.0f, 1.0f
};

const static GLfloat defaultTexCoordData[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f
};

static  uint8_t* tfIn = 0;
static  uint8_t* tfOut = 0;
static float tfParams[GLENV_PARAM_MAX_NUM] = {0};
static unsigned int tfRet = 0;

const int texCdAtbSize2 = 2;
const int posAtbSize4 = 4;
const int drawCount = 4;
const int proInfoBufSize = 512;
const int shaderInfoBufSize = 512;
const int glver = 3;


void tfInit()
{
    if (!tfEnv.isInit) {
        tfEnv.display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        eglInitialize(tfEnv.display, &tfEnv.major, &tfEnv.minor);
        EGLint nConf;
        EGLint confAttrs[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RED_SIZE,
            8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
        eglChooseConfig(tfEnv.display, confAttrs, &tfEnv.config, 1, &nConf);
        tfEnv.glVersion = glver;
        tfGenSurface(1, 1);
        tfInitPrograms();
        tfEnv.isInit = true;
    }
}

void tfRelease()
{
    for (GLuint i = 0; i < IdxNum; ++i) {
        glDeleteProgram(tfEnv.progIds[i]);
    }

    tfReleaseSurface();
    tfReleaseContext();
    tfReleaseDisplay();

    tfEnv.display = NULL;
    tfEnv.major = 0;
    tfEnv.minor = 0;
    tfEnv.config = NULL;
    tfEnv.surface = NULL;
    tfEnv.context = NULL;
    tfEnv.wSurf = 0;
    tfEnv.hSurf = 0;
    tfEnv.isInit = false;
}

void tfReleaseSurface()
{
    if (tfEnv.surface) {
        eglDestroySurface(tfEnv.display, tfEnv.surface);
        tfEnv.surface = NULL;
    }
}

void tfReleaseContext()
{
    if (tfEnv.context) {
        eglDestroyContext(tfEnv.display, tfEnv.context);
        tfEnv.context = NULL;
    }
}

void tfReleaseDisplay()
{
    if (tfEnv.display) {
        eglTerminate(tfEnv.display);
        tfEnv.display = NULL;
    }
}

void tfGenSurface(int w, int h)
{
    if (tfEnv.surface) {
        if (w == tfEnv.wSurf && h == tfEnv.hSurf) {
            eglMakeCurrent(tfEnv.display, tfEnv.surface, tfEnv.surface, tfEnv.context);
            return;
        } else {
            tfReleaseSurface();
        }
    }

    EGLint surfAttrs[] = {EGL_WIDTH, w, EGL_HEIGHT, h, EGL_NONE};
    tfEnv.surface = eglCreatePbufferSurface(tfEnv.display, tfEnv.config, surfAttrs);
    if (!tfEnv.context) {
        EGLint cntxtAttrs[] = {EGL_CONTEXT_CLIENT_VERSION, tfEnv.glVersion, EGL_NONE};
        tfEnv.context = eglCreateContext(tfEnv.display, tfEnv.config, EGL_NO_CONTEXT, cntxtAttrs);
    }
    eglMakeCurrent(tfEnv.display, tfEnv.surface, tfEnv.surface, tfEnv.context);
}

GLuint tfDoShader(const char* shaderStr, int type)
{
    GLint success;
    char str[512];
    GLuint id = glCreateShader(type);
    printf("gl_log shader id : %d\n", id);
    glShaderSource(id, 1, &shaderStr, NULL);
    glCompileShader(id);
    glGetShaderiv(id, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(id, shaderInfoBufSize, NULL, str);
        printf("gl_log shader err : %d , \n%s\n", type, str);
        glDeleteShader(id);
    }
    return id;
}

GLuint tfDoProgram(const char* vs, const char* fs)
{
    GLuint vsId = tfDoShader(vs, GL_VERTEX_SHADER);
    if (!vsId) return 0;
    GLuint fsId = tfDoShader(fs, GL_FRAGMENT_SHADER);
    if (!fsId) return 0;

    GLuint progId = glCreateProgram();
    printf("gl_log progId : %d, %d, %d\n", progId, vsId, fsId);
    glAttachShader(progId, vsId);
    glAttachShader(progId, fsId);
    glLinkProgram(progId);

    GLint success;
    char str[512];
    glGetProgramiv(progId, GL_LINK_STATUS, &success);
    glDetachShader(progId, vsId);
    glDeleteShader(vsId);
    glDetachShader(progId, fsId);
    glDeleteShader(fsId);
    if (!success) {
        glGetProgramInfoLog(progId, proInfoBufSize, NULL, str);
        printf("gl_log link program err : \n%s\n", str);
        return 0;
    }
    glDeleteShader(vsId);
    glDeleteShader(fsId);
    return progId;
}

void tfInitPrograms()
{
    printf("gl_log program context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    std::char_traits<GLuint>::assign(tfEnv.progIds, 0, IdxNum);
    tfEnv.progIds[brightIdx] = tfDoProgram(defaultVs, brightFs);
    tfEnv.progIds[contrastIdx] = tfDoProgram(defaultVs, contrastFs);
    tfEnv.progIds[grayscaleIdx] = tfDoProgram(defaultVs, grayscaleFs);
    tfEnv.progIds[invertIdx] = tfDoProgram(defaultVs, invertFs);
    tfEnv.progIds[kuwaharaIdx] = tfDoProgram(defaultVs, kuwaharaFs);
    tfEnv.progIds[pixelationIdx] = tfDoProgram(defaultVs, pixFs);
    tfEnv.progIds[sepiaIdx] = tfDoProgram(defaultVs, sepiaFs);
    tfEnv.progIds[sketchIdx] = tfDoProgram(sketchVs, sketchFs);
    tfEnv.progIds[swirlIdx] = tfDoProgram(defaultVs, swirlFs);
    tfEnv.progIds[toonIdx] = tfDoProgram(toonVs, toonFs);
    tfEnv.progIds[vignetteIdx] = tfDoProgram(defaultVs, vigFs);
    tfEnv.progIds[fitcenterIdx] = tfDoProgram(defaultVs, defaultFs);
    tfEnv.progIds[centerinsideIdx] = tfDoProgram(defaultVs, defaultFs);
    tfEnv.progIds[centercropIdx] = tfDoProgram(defaultVs, defaultFs);
    tfEnv.progIds[circlecropIdx] = tfDoProgram(defaultVs, circlecropFs);
    tfEnv.progIds[roundedcornersIdx] = tfDoProgram(defaultVs, roundedcornersFs);
    tfEnv.progIds[rotateIdx] = tfDoProgram(defaultVs, defaultFs);
    tfEnv.progIds[fastblurIdx] = tfDoProgram(defaultVs, fastblurFs);

    for (GLuint i = 0; i < IdxNum; ++i) {
        printf("gl_log prog[%d]: %d\n", i, tfEnv.progIds[i]);
    }
}

void tfLoadTextureRGBA(GLuint tex, GLubyte* data, GLsizei w, GLsizei h)
{
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}


GLuint brightnessFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat bright = tfParams[4];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- brightnessFilter : %d, %d, %d, %f\n", w, h, c, bright);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progBrightnessFilter = tfEnv.progIds[brightIdx];
    glUseProgram(progBrightnessFilter);
    GLuint posAtbBrightnessFilter = glGetAttribLocation(progBrightnessFilter, "a_position");
    glEnableVertexAttribArray(posAtbBrightnessFilter);
    glVertexAttribPointer(posAtbBrightnessFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbBrightnessFilter = glGetAttribLocation(progBrightnessFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbBrightnessFilter);
    glVertexAttribPointer(texCdAtbBrightnessFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint brightUni = glGetUniformLocation(progBrightnessFilter, "brightness");
    glUniform1f(brightUni, bright);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progBrightnessFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbBrightnessFilter);
    glDisableVertexAttribArray(texCdAtbBrightnessFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint contrastFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat contrast = tfParams[4];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- contrastFilter : %d, %d, %d, %f\n", w, h, c, contrast);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progContrastFilter = tfEnv.progIds[contrastIdx];
    glUseProgram(progContrastFilter);
    GLuint posAtbContrastFilter = glGetAttribLocation(progContrastFilter, "a_position");
    glEnableVertexAttribArray(posAtbContrastFilter);
    glVertexAttribPointer(posAtbContrastFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbContrastFilter = glGetAttribLocation(progContrastFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbContrastFilter);
    glVertexAttribPointer(texCdAtbContrastFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint contrastUni = glGetUniformLocation(progContrastFilter, "contrast");
    glUniform1f(contrastUni, contrast);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progContrastFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbContrastFilter);
    glDisableVertexAttribArray(texCdAtbContrastFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint grayscale()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- grayscaleFilter : %d, %d, %d\n", w, h, c);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progGrayScale = tfEnv.progIds[grayscaleIdx];
    glUseProgram(progGrayScale);
    GLuint posAtbGrayscale = glGetAttribLocation(progGrayScale, "a_position");
    glEnableVertexAttribArray(posAtbGrayscale);
    glVertexAttribPointer(posAtbGrayscale, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbGrayscale = glGetAttribLocation(progGrayScale, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbGrayscale);
    glVertexAttribPointer(texCdAtbGrayscale, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progGrayScale, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbGrayscale);
    glDisableVertexAttribArray(texCdAtbGrayscale);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint invertFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- invertFilter : %d, %d, %d\n", w, h, c);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progInvertFilter = tfEnv.progIds[invertIdx];
    glUseProgram(progInvertFilter);
    GLuint posAtbInvertFilter = glGetAttribLocation(progInvertFilter, "a_position");
    glEnableVertexAttribArray(posAtbInvertFilter);
    glVertexAttribPointer(posAtbInvertFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbInvertFilter = glGetAttribLocation(progInvertFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbInvertFilter);
    glVertexAttribPointer(texCdAtbInvertFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progInvertFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbInvertFilter);
    glDisableVertexAttribArray(texCdAtbInvertFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint kuwaharaFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLint radius = (GLint)(tfParams[4]);
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- kuwaharaFilter : %d, %d, %d, %d\n", w, h, c, radius);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progKuwaharaFilter = tfEnv.progIds[kuwaharaIdx];
    glUseProgram(progKuwaharaFilter);
    GLuint posAtbKuwaharaFilter = glGetAttribLocation(progKuwaharaFilter, "a_position");
    glEnableVertexAttribArray(posAtbKuwaharaFilter);
    glVertexAttribPointer(posAtbKuwaharaFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbKuwaharaFilter = glGetAttribLocation(progKuwaharaFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbKuwaharaFilter);
    glVertexAttribPointer(texCdAtbKuwaharaFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint radiusUni = glGetUniformLocation(progKuwaharaFilter, "radius");
    glUniform1i(radiusUni, radius);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progKuwaharaFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbKuwaharaFilter);
    glDisableVertexAttribArray(texCdAtbKuwaharaFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint pixlationFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat pixel = tfParams[4];
    GLfloat wFactor = tfParams[5];
    GLfloat hFactor = tfParams[6];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- pixelationFilter : %d, %d, %d, %f\n", w, h, c, pixel);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progPixlationFilter = tfEnv.progIds[pixelationIdx];
    glUseProgram(progPixlationFilter);
    GLuint posAtbPixlationFilter = glGetAttribLocation(progPixlationFilter, "a_position");
    glEnableVertexAttribArray(posAtbPixlationFilter);
    glVertexAttribPointer(posAtbPixlationFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbPixlationFilter = glGetAttribLocation(progPixlationFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbPixlationFilter);
    glVertexAttribPointer(texCdAtbPixlationFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint pixelUni = glGetUniformLocation(progPixlationFilter, "pixel");
    glUniform1f(pixelUni, pixel);
    GLuint wFactorUni = glGetUniformLocation(progPixlationFilter, "wFactor");
    glUniform1f(wFactorUni, wFactor);
    GLuint hFactorUni = glGetUniformLocation(progPixlationFilter, "hFactor");
    glUniform1f(hFactorUni, hFactor);
    printf("gl_log pixelationFilter uni: %d, %d, %d, %d, %d\n",
        texId, progPixlationFilter, pixelUni, wFactorUni, hFactorUni);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progPixlationFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbPixlationFilter);
    glDisableVertexAttribArray(texCdAtbPixlationFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}


GLuint sepiaFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat intensity = tfParams[4];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- sepiaFilter : %d, %d, %d, %f\n", w, h, c, intensity);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progSepiaFilter = tfEnv.progIds[sepiaIdx];
    glUseProgram(progSepiaFilter);
    GLuint posAtbSepiaFilter = glGetAttribLocation(progSepiaFilter, "a_position");
    glEnableVertexAttribArray(posAtbSepiaFilter);
    glVertexAttribPointer(posAtbSepiaFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbSepiaFilter = glGetAttribLocation(progSepiaFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbSepiaFilter);
    glVertexAttribPointer(texCdAtbSepiaFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint intensityUni = glGetUniformLocation(progSepiaFilter, "intensity");
    glUniform1f(intensityUni, intensity);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progSepiaFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbSepiaFilter);
    glDisableVertexAttribArray(texCdAtbSepiaFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint sketchFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat wTexel = tfParams[4];
    GLfloat hTexel = tfParams[5];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- sketchFilter : %d, %d, %d, %f, %f\n", w, h, c, wTexel, hTexel);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progSketchFilter = tfEnv.progIds[sketchIdx];
    glUseProgram(progSketchFilter);
    GLuint posAtbSketchFilter = glGetAttribLocation(progSketchFilter, "a_position");
    glEnableVertexAttribArray(posAtbSketchFilter);
    glVertexAttribPointer(posAtbSketchFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbSketchFilter = glGetAttribLocation(progSketchFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbSketchFilter);
    glVertexAttribPointer(texCdAtbSketchFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint wTexelUni = glGetUniformLocation(progSketchFilter, "texelWidth");
    glUniform1f(wTexelUni, wTexel);
    GLuint hTexelUni = glGetUniformLocation(progSketchFilter, "texelHeight");
    glUniform1f(hTexelUni, hTexel);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progSketchFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbSketchFilter);
    glDisableVertexAttribArray(texCdAtbSketchFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint swirlFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat radius = tfParams[4];
    GLfloat angle = tfParams[5];
    GLfloat xc = tfParams[6];
    GLfloat yc = tfParams[7];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- swirlFilter : %d, %d, %d, %f, %f, %f, %f\n", w, h, c, radius, angle, xc, yc);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progSwirlFilter = tfEnv.progIds[swirlIdx];
    glUseProgram(progSwirlFilter);
    GLuint posAtbSwirlFilter = glGetAttribLocation(progSwirlFilter, "a_position");
    glEnableVertexAttribArray(posAtbSwirlFilter);
    glVertexAttribPointer(posAtbSwirlFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbSwirlFilter = glGetAttribLocation(progSwirlFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbSwirlFilter);
    glVertexAttribPointer(texCdAtbSwirlFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint radiusUni = glGetUniformLocation(progSwirlFilter, "radius");
    glUniform1f(radiusUni, radius);
    GLuint angleUni = glGetUniformLocation(progSwirlFilter, "angle");
    glUniform1f(angleUni, angle);
    GLuint centerUni = glGetUniformLocation(progSwirlFilter, "center");
    glUniform2f(centerUni, xc, yc);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progSwirlFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbSwirlFilter);
    glDisableVertexAttribArray(texCdAtbSwirlFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint toonFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat wTexel = tfParams[4];
    GLfloat hTexel = tfParams[5];
    GLfloat threshold = tfParams[6];
    GLfloat quantizationLevels = tfParams[7];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- toonFilter : %d, %d, %d, %f, %f, %f, %f\n",
        w, h, c, wTexel, hTexel, threshold, quantizationLevels);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progToonFilter = tfEnv.progIds[toonIdx];
    glUseProgram(progToonFilter);
    GLuint posAtbToonFilter = glGetAttribLocation(progToonFilter, "a_position");
    glEnableVertexAttribArray(posAtbToonFilter);
    glVertexAttribPointer(posAtbToonFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbToonFilter = glGetAttribLocation(progToonFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbToonFilter);
    glVertexAttribPointer(texCdAtbToonFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint wTexelUni = glGetUniformLocation(progToonFilter, "texelWidth");
    glUniform1f(wTexelUni, wTexel);
    GLuint hTexelUni = glGetUniformLocation(progToonFilter, "texelHeight");
    glUniform1f(hTexelUni, hTexel);
    GLuint thresholdUni = glGetUniformLocation(progToonFilter, "threshold");
    glUniform1f(thresholdUni, threshold);
    GLuint quantiUni = glGetUniformLocation(progToonFilter, "quantizationLevels");
    glUniform1f(quantiUni, quantizationLevels);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progToonFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbToonFilter);
    glDisableVertexAttribArray(texCdAtbToonFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint vignetteFilter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat xc = tfParams[4];
    GLfloat yc = tfParams[5];
    GLfloat r = tfParams[6];
    GLfloat g = tfParams[7];
    GLfloat b = tfParams[8];
    GLfloat start = tfParams[9];
    GLfloat end = tfParams[10];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progVignetteFilter = tfEnv.progIds[vignetteIdx];
    glUseProgram(progVignetteFilter);
    GLuint posAtbVignetteFilter = glGetAttribLocation(progVignetteFilter, "a_position");
    glEnableVertexAttribArray(posAtbVignetteFilter);
    glVertexAttribPointer(posAtbVignetteFilter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbVignetteFilter = glGetAttribLocation(progVignetteFilter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbVignetteFilter);
    glVertexAttribPointer(texCdAtbVignetteFilter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint ctUni = glGetUniformLocation(progVignetteFilter, "vignetteCenter");
    glUniform2f(ctUni, xc, yc);
    GLuint clrUni = glGetUniformLocation(progVignetteFilter, "vignetteColor");
    glUniform3f(clrUni, r, g, b);
    GLuint startUni = glGetUniformLocation(progVignetteFilter, "vignetteStart");
    glUniform1f(startUni, start);
    GLuint endUni = glGetUniformLocation(progVignetteFilter, "vignetteEnd");
    glUniform1f(endUni, end);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progVignetteFilter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbVignetteFilter);
    glDisableVertexAttribArray(texCdAtbVignetteFilter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

const int rotateVx1Value = 6;
const int rotateVx2Value = 7;
const int rotateVxIndex1 = 2;
const int rotateVxIndex2 = 3;
const int rotateVx3Value = 8;
const int rotateVx4Value = 9;
const int rotateVy1Value = 10;
const int rotateVy2Value = 11;
const int rotateVyIndex1 = 2;
const int rotateVyIndex2 = 3;
const int rotateVy3Value = 12;
const int rotateVy4Value = 13;

GLuint rotate()
{
    GLfloat vx[4] = {0};
    GLfloat vy[4] = {0};
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLsizei wo = (GLsizei)(tfParams[4]);
    GLsizei ho = (GLsizei)(tfParams[5]);
    vx[0] = tfParams[rotateVx1Value];
    vx[1] = tfParams[rotateVx2Value];
    vx[rotateVxIndex1] = tfParams[rotateVx3Value];
    vx[rotateVxIndex2] = tfParams[rotateVx4Value];
    vy[0] = tfParams[rotateVy1Value];
    vy[1] = tfParams[rotateVy2Value];
    vy[rotateVyIndex1] = tfParams[rotateVy3Value];
    vy[rotateVyIndex2] = tfParams[rotateVy4Value];
    GLfloat vertexData[] = {vx[0], vy[0], 0.0, 1.0, vx[1],
        vy[1], 0.0, 1.0, vx[2], vy[2], 0.0, 1.0, vx[3], vy[3], 0.0, 1.0};
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- rotate : %d, %d, %d\n", w, h, c);
    
    tfGenSurface(wo, ho);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progRotate = tfEnv.progIds[rotateIdx];
    glUseProgram(progRotate);
    GLuint posAtbRotate = glGetAttribLocation(progRotate, "a_position");
    glEnableVertexAttribArray(posAtbRotate);
    glVertexAttribPointer(posAtbRotate, posAtbSize4, GL_FLOAT, GL_FALSE, 0, vertexData);
    GLuint texCdAtbRotate = glGetAttribLocation(progRotate, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbRotate);
    glVertexAttribPointer(texCdAtbRotate, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progRotate, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, wo, ho);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbRotate);
    glDisableVertexAttribArray(texCdAtbRotate);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint centerCrop()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat dx = tfParams[4];
    GLfloat dy = tfParams[5];
    GLsizei wo = (GLsizei)(tfParams[6]);
    GLsizei ho = (GLsizei)(tfParams[7]);
    GLfloat vertexData[] = {-dx, -dy, 0.0, 1.0, dx, -dy, 0.0, 1.0, -dx, dy, 0.0, 1.0, dx, dy, 0.0, 1.0};
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- centerCrop : %d, %d, %d, %f, %f\n", w, h, c, dx, dy);
    
    tfGenSurface(wo, ho);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progCenterCrop = tfEnv.progIds[centercropIdx];
    glUseProgram(progCenterCrop);
    GLuint posAtbCenterCrop = glGetAttribLocation(progCenterCrop, "a_position");
    glEnableVertexAttribArray(posAtbCenterCrop);
    glVertexAttribPointer(posAtbCenterCrop, posAtbSize4, GL_FLOAT, GL_FALSE, 0, vertexData);
    GLuint texCdAtbCenterCrop = glGetAttribLocation(progCenterCrop, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbCenterCrop);
    glVertexAttribPointer(texCdAtbCenterCrop, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progCenterCrop, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, wo, ho);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);
    glDisableVertexAttribArray(posAtbCenterCrop);
    glDisableVertexAttribArray(texCdAtbCenterCrop);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint centerInside()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLsizei wo = (GLsizei)(tfParams[4]);
    GLsizei ho = (GLsizei)(tfParams[5]);
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- centerCrop : %d, %d, %d, %d, %d\n", w, h, c, wo, ho);
    
    tfGenSurface(wo, ho);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progCenterInside = tfEnv.progIds[centerinsideIdx];
    glUseProgram(progCenterInside);
    GLuint posAtbCenterInside = glGetAttribLocation(progCenterInside, "a_position");
    glEnableVertexAttribArray(posAtbCenterInside);
    glVertexAttribPointer(posAtbCenterInside, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbCenterInside = glGetAttribLocation(progCenterInside, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbCenterInside);
    glVertexAttribPointer(texCdAtbCenterInside, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progCenterInside, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, wo, ho);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbCenterInside);
    glDisableVertexAttribArray(texCdAtbCenterInside);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint fitCenter()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLsizei wo = (GLsizei)(tfParams[4]);
    GLsizei ho = (GLsizei)(tfParams[5]);
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- fitCenter : %d, %d, %d, %d, %d\n", w, h, c, wo, ho);
    
    tfGenSurface(wo, ho);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progFitCenter = tfEnv.progIds[fitcenterIdx];
    glUseProgram(progFitCenter);
    GLuint posAtbFitCenter = glGetAttribLocation(progFitCenter, "a_position");
    glEnableVertexAttribArray(posAtbFitCenter);
    glVertexAttribPointer(posAtbFitCenter, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbFitCenter = glGetAttribLocation(progFitCenter, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbFitCenter);
    glVertexAttribPointer(texCdAtbFitCenter, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progFitCenter, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, wo, ho);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbFitCenter);
    glDisableVertexAttribArray(texCdAtbFitCenter);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint circleCrop()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat dx = tfParams[4];
    GLfloat dy = tfParams[5];
    GLsizei wo = (GLsizei)(tfParams[6]);
    GLsizei ho = wo;
    GLfloat vertexData[] = {-dx, -dy, 0.0, 1.0, dx, -dy, 0.0, 1.0, -dx, dy, 0.0, 1.0, dx, dy, 0.0, 1.0};
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- circleCrop : %d, %d, %d, %f, %f\n", w, h, c, dx, dy);
    
    tfGenSurface(wo, ho);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progCircleCrop = tfEnv.progIds[circlecropIdx];
    glUseProgram(progCircleCrop);
    GLuint posAtbCircleCrop = glGetAttribLocation(progCircleCrop, "a_position");
    glEnableVertexAttribArray(posAtbCircleCrop);
    glVertexAttribPointer(posAtbCircleCrop, posAtbSize4, GL_FLOAT, GL_FALSE, 0, vertexData);
    GLuint texCdAtbCircleCrop = glGetAttribLocation(progCircleCrop, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbCircleCrop);
    glVertexAttribPointer(texCdAtbCircleCrop, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint resUni = glGetUniformLocation(progCircleCrop, "resolution");
    glUniform2f(resUni, (GLfloat)w, (GLfloat)h);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progCircleCrop, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, wo, ho);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbCircleCrop);
    glDisableVertexAttribArray(texCdAtbCircleCrop);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint roundedCorners()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat radiusTL = tfParams[4];
    GLfloat radiusTR = tfParams[5];
    GLfloat radiusBL = tfParams[6];
    GLfloat radiusBR = tfParams[7];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- roundedcorners : %d, %d, %d, %f, %f, %f, %f\n",
        w, h, c, radiusTL, radiusTR, radiusBL, radiusBR);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progRoundedCorners = tfEnv.progIds[roundedcornersIdx];
    glUseProgram(progRoundedCorners);
    GLuint posAtbRoundedCorners = glGetAttribLocation(progRoundedCorners, "a_position");
    glEnableVertexAttribArray(posAtbRoundedCorners);
    glVertexAttribPointer(posAtbRoundedCorners, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbRoundedCorners = glGetAttribLocation(progRoundedCorners, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbRoundedCorners);
    glVertexAttribPointer(texCdAtbRoundedCorners, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint resUni = glGetUniformLocation(progRoundedCorners, "resolution");
    glUniform2f(resUni, (GLfloat)w, (GLfloat)h);
    // 1 bl, 2 br, 3 tl, 4 tr
    GLuint rblUni = glGetUniformLocation(progRoundedCorners, "radius1");
    glUniform1f(rblUni, radiusBL);
    GLuint rbrUni = glGetUniformLocation(progRoundedCorners, "radius2");
    glUniform1f(rbrUni, radiusBR);
    GLuint rtlUni = glGetUniformLocation(progRoundedCorners, "radius3");
    glUniform1f(rtlUni, radiusTL);
    GLuint rtrUni = glGetUniformLocation(progRoundedCorners, "radius4");
    glUniform1f(rtrUni, radiusTR);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progRoundedCorners, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbRoundedCorners);
    glDisableVertexAttribArray(texCdAtbRoundedCorners);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

GLuint fastBlur()
{
    GLsizei w = (GLsizei)(tfParams[1]);
    GLsizei h = (GLsizei)(tfParams[2]);
    GLsizei c = (GLsizei)(tfParams[3]);
    GLfloat radius = tfParams[4];
    printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    printf("gl_log -cc- fastBlur : %d, %d, %d, %f\n", w, h, c, radius);
    
    tfGenSurface(w, h);
    
    GLuint texId;
    glGenTextures(1, &texId);
    if (!texId) return tfTexError;
    tfLoadTextureRGBA(texId, tfIn, w, h);

    GLuint progFastBlur = tfEnv.progIds[fastblurIdx];
    glUseProgram(progFastBlur);
    GLuint posAtbFastBlur = glGetAttribLocation(progFastBlur, "a_position");
    glEnableVertexAttribArray(posAtbFastBlur);
    glVertexAttribPointer(posAtbFastBlur, posAtbSize4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
    GLuint texCdAtbFastBlur = glGetAttribLocation(progFastBlur, "a_texcoord");
    glEnableVertexAttribArray(texCdAtbFastBlur);
    glVertexAttribPointer(texCdAtbFastBlur, texCdAtbSize2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

    GLuint radiusUni = glGetUniformLocation(progFastBlur, "r");
    glUniform1i(radiusUni, radius);

    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, texId);
    GLuint texUni = glGetUniformLocation(progFastBlur, "u_texture");
    glUniform1i(texUni, 0);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, w, h);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, drawCount);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

    glDisableVertexAttribArray(posAtbFastBlur);
    glDisableVertexAttribArray(texCdAtbFastBlur);
    glBindTexture(GL_TEXTURE_2D, GL_NONE);
    glDeleteTextures(1, &texId);

    glFinish();

    return 0;
}

unsigned int tfProc()
{
    printf("gl_log -cc- tfProc context : %lu, %lu, %lu, %lu\n",
        (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW),
        (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
    int type = (int)(tfParams[0]);
    switch (type) {
        case brightIdx:
            return brightnessFilter();
        case contrastIdx:
            return contrastFilter();
        case grayscaleIdx:
            return grayscale();
        case invertIdx:
            return invertFilter();
        case kuwaharaIdx:
            return kuwaharaFilter();
        case pixelationIdx:
            return pixlationFilter();
        case sepiaIdx:
            return sepiaFilter();
        case sketchIdx:
            return sketchFilter();
        case swirlIdx:
            return swirlFilter();
        case toonIdx:
            return toonFilter();
        case vignetteIdx:
            return vignetteFilter();
        case rotateIdx:
            return rotate();
        case centercropIdx:
            return centerCrop();
        case centerinsideIdx:
            return centerInside();
        case fitcenterIdx:
            return fitCenter();
        case circlecropIdx:
            return circleCrop();
        case roundedcornersIdx:
            return roundedCorners();
        case fastblurIdx:
            return fastBlur();
        default:
            printf("gl_log should not go tfProc default\n");
            return tfProcError;
    }
}


static unsigned int param = 0;
static unsigned int res = 0;

pthread_mutex_t mutexGlEnv;
pthread_mutex_t mutex;
pthread_cond_t cond;
int ready = 0;
int ready2 = 0;

pthread_mutex_t mutex2;
pthread_cond_t cond2;

bool tFlg = true;

void* thread_func(void* args)
{
    int ret;
    
    ret = pthread_detach(pthread_self());
    if (ret) {
        printf("gl_log c error: pthread_detach fail : %d\n", ret);
    }
    pthread_mutex_lock(&mutexGlEnv);
    tfInit();
    pthread_mutex_unlock(&mutexGlEnv);

    while (tFlg) {
        printf("gl_log thread ready : %lu\n", getThreadId());
        pthread_mutex_lock(&mutex);
        ready = 0;
        while (!ready) {
            pthread_cond_wait(&cond, &mutex);
        }
        pthread_mutex_unlock(&mutex);

        tfProc();
        pthread_mutex_lock(&mutex2);
        ready2 = 1;
        pthread_cond_broadcast(&cond2);
        pthread_mutex_unlock(&mutex2);
    }

    tfRelease();
}

unsigned long int startThread()
{
    tFlg = true;
    ready = 0;
    ready2 = 0;

    pthread_t th1;
    pthread_mutex_init(&mutex, NULL);
    pthread_cond_init(&cond, NULL);
    pthread_mutex_init(&mutex2, NULL);
    pthread_cond_init(&cond2, NULL);
    
    pthread_create(&th1, NULL, thread_func, NULL);
    return th1;
}

void stopThread()
{
    tFlg = false;
    if (!ready) {
        pthread_mutex_lock(&mutex);
        ready = 1;
        pthread_cond_broadcast(&cond);
        pthread_mutex_unlock(&mutex);
    }
}

unsigned int getThreadId()
{
    return (unsigned int)(pthread_self());
}

static void pThreadLock()
{
    pthread_mutex_lock(&mutex);
    ready = 1;
    pthread_cond_broadcast(&cond);
    pthread_mutex_unlock(&mutex);

    pthread_mutex_lock(&mutex2);
    ready2 = 0;
    while (!ready2) {
        pthread_cond_wait(&cond2, &mutex2);
    }
    pthread_mutex_unlock(&mutex2);
}

unsigned int setTask(unsigned int a)
{
    pthread_mutex_lock(&mutexGlEnv);
    param = a;
    pthread_mutex_unlock(&mutexGlEnv);

    pThreadLock();

    return res;
}

unsigned int tfTask(uint8_t* pOut,
                    uint8_t* pIn,
                    float* pparam)
{
    pthread_mutex_lock(&mutexGlEnv);
    std::char_traits<float>::copy(tfParams, pparam, GLENV_PARAM_MAX_NUM);
    tfIn = pIn;
    tfOut = pOut;

    pThreadLock();
    pthread_mutex_unlock(&mutexGlEnv);

    return tfRet;
}

