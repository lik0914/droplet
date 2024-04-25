#include "gl_wrapper.h"

///////////////////////////////////////////////////////////////

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


///////////////////////////////////////////////////////////////

static TFEnv tfEnv = {false, NULL, 0, 0, NULL, NULL, NULL, 0, 0, 0, {0}};

const static GLfloat defaultVertexData[] =
{
  -1.0f, -1.0f, 0.0f, 1.0f,
  1.0f, -1.0f, 0.0f, 1.0f,
  -1.0f,  1.0f, 0.0f, 1.0f,
  1.0f,  1.0f, 0.0f, 1.0f
};
#if 0
const static GLfloat defaultTexCoordData[] =
{
  0.0f, 1.0f, // bottom left
  1.0f, 1.0f, // bottom right
  0.0f, 0.0f, // top left
  1.0f, 0.0f, // top right
};
#else
const static GLfloat defaultTexCoordData[] = {
    0.0f, 0.0f, // bottom left
    1.0f, 0.0f, // bottom right
    0.0f, 1.0f, // top left
    1.0f, 1.0f, // top right
};
#endif

static unsigned char* tfIn = 0;
static unsigned char* tfOut = 0;
static float tfParams[GLENV_PARAM_MAX_NUM] = {0};
static unsigned int tfRet = 0;

///////////////////////////////////////////////////////////////
void tfInit()
{
  if (!tfEnv.isInit)
  {
    tfEnv.display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    eglInitialize(tfEnv.display, &tfEnv.major, &tfEnv.minor);
    EGLint nConf;
    EGLint confAttrs[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
    eglChooseConfig(tfEnv.display, confAttrs, &tfEnv.config, 1, &nConf);
    tfEnv.glVersion = 3;
    tfGenSurface(1, 1);
    tfInitPrograms();
    tfEnv.isInit = true;
  }
}

void tfRelease()
{
  for (GLuint i = 0; i < IdxNum; ++i)
  {
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
  if (tfEnv.surface)
  {
    eglDestroySurface(tfEnv.display, tfEnv.surface);
    tfEnv.surface = NULL;
  }
}

void tfReleaseContext()
{
  if (tfEnv.context)
  {
    eglDestroyContext(tfEnv.display, tfEnv.context);
    tfEnv.context = NULL;
  }
}

void tfReleaseDisplay()
{
  if (tfEnv.display)
  {
    eglTerminate(tfEnv.display);
    tfEnv.display = NULL;
  }
}

void tfGenSurface(int w, int h)
{
  if (tfEnv.surface)
  {
    if (w == tfEnv.wSurf && h == tfEnv.hSurf)
    {
      eglMakeCurrent(tfEnv.display, tfEnv.surface, tfEnv.surface, tfEnv.context);
      return;
    }
    else
    {
      tfReleaseSurface();
    }
  }

  EGLint surfAttrs[] = {EGL_WIDTH, w, EGL_HEIGHT, h, EGL_NONE};
  tfEnv.surface = eglCreatePbufferSurface(tfEnv.display, tfEnv.config, surfAttrs);
  if (!tfEnv.context)
  {
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
  //printf("gl_log shader id : %d , \n%s\n", id, shaderStr);
  glShaderSource(id, 1, &shaderStr, NULL);
  glCompileShader(id);
  glGetShaderiv(id, GL_COMPILE_STATUS, &success);
  if(!success)
  {
    glGetShaderInfoLog(id, 512, NULL, str);
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
  if(!success)
  {
    glGetProgramInfoLog(progId, 512, NULL, str);
    printf("gl_log link program err : \n%s\n", str);
    return 0;
  }
  glDeleteShader(vsId);
  glDeleteShader(fsId);
  return progId;
}

void tfInitPrograms()
{
  printf("gl_log program context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  memset(tfEnv.progIds, 0, sizeof(GLuint) * IdxNum);
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

  for (GLuint i = 0; i < IdxNum; ++i)
  {
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

///////////////////////////////////////////////////////////////

GLuint brightnessFilter()
{
  GLsizei w = (GLsizei)(tfParams[1]);
  GLsizei h = (GLsizei)(tfParams[2]);
  GLsizei c = (GLsizei)(tfParams[3]);
  GLfloat bright = tfParams[4];
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- brightnessFilter : %d, %d, %d, %f\n", w, h, c, bright);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[brightIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint brightUni = glGetUniformLocation(prog, "brightness");
  glUniform1f(brightUni, bright);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- contrastFilter : %d, %d, %d, %f\n", w, h, c, contrast);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[contrastIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint contrastUni = glGetUniformLocation(prog, "contrast");
  glUniform1f(contrastUni, contrast);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- grayscaleFilter : %d, %d, %d\n", w, h, c);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[grayscaleIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- invertFilter : %d, %d, %d\n", w, h, c);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[invertIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- kuwaharaFilter : %d, %d, %d, %d\n", w, h, c, radius);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[kuwaharaIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint radiusUni = glGetUniformLocation(prog, "radius");
  glUniform1i(radiusUni, radius);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- pixelationFilter : %d, %d, %d, %f\n", w, h, c, pixel);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[pixelationIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint pixelUni = glGetUniformLocation(prog, "pixel");
  glUniform1f(pixelUni, pixel);
  GLuint wFactorUni = glGetUniformLocation(prog, "wFactor");
  glUniform1f(wFactorUni, wFactor);
  GLuint hFactorUni = glGetUniformLocation(prog, "hFactor");
  glUniform1f(hFactorUni, hFactor);
  printf("gl_log pixelationFilter uni: %d, %d, %d, %d, %d\n", texId, prog, pixelUni, wFactorUni, hFactorUni);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- sepiaFilter : %d, %d, %d, %f\n", w, h, c, intensity);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[sepiaIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint intensityUni = glGetUniformLocation(prog, "intensity");
  glUniform1f(intensityUni, intensity);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- sketchFilter : %d, %d, %d, %f, %f\n", w, h, c, wTexel, hTexel);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[sketchIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint wTexelUni = glGetUniformLocation(prog, "texelWidth");
  glUniform1f(wTexelUni, wTexel);
  GLuint hTexelUni = glGetUniformLocation(prog, "texelHeight");
  glUniform1f(hTexelUni, hTexel);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- swirlFilter : %d, %d, %d, %f, %f, %f, %f\n", w, h, c, radius, angle, xc, yc);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[swirlIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint radiusUni = glGetUniformLocation(prog, "radius");
  glUniform1f(radiusUni, radius);
  GLuint angleUni = glGetUniformLocation(prog, "angle");
  glUniform1f(angleUni, angle);
  GLuint centerUni = glGetUniformLocation(prog, "center");
  glUniform2f(centerUni, xc, yc);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- toonFilter : %d, %d, %d, %f, %f, %f, %f\n", w, h, c, wTexel, hTexel, threshold, quantizationLevels);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[toonIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint wTexelUni = glGetUniformLocation(prog, "texelWidth");
  glUniform1f(wTexelUni, wTexel);
  GLuint hTexelUni = glGetUniformLocation(prog, "texelHeight");
  glUniform1f(hTexelUni, hTexel);
  GLuint thresholdUni = glGetUniformLocation(prog, "threshold");
  glUniform1f(thresholdUni, threshold);
  GLuint quantiUni = glGetUniformLocation(prog, "quantizationLevels");
  glUniform1f(quantiUni, quantizationLevels);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- vignetteFilter : %d, %d, %d, %f, %f, %f, %f, %f, %f, %f\n", w, h, c, xc, yc, r, g, b, start, end);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[vignetteIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint ctUni = glGetUniformLocation(prog, "vignetteCenter");
  glUniform2f(ctUni, xc, yc);
  GLuint clrUni = glGetUniformLocation(prog, "vignetteColor");
  glUniform3f(clrUni, r, g, b);
  GLuint startUni = glGetUniformLocation(prog, "vignetteStart");
  glUniform1f(startUni, start);
  GLuint endUni = glGetUniformLocation(prog, "vignetteEnd");
  glUniform1f(endUni, end);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
  glBindTexture(GL_TEXTURE_2D, GL_NONE);
  glDeleteTextures(1, &texId);

  glFinish();

  return 0;
}

GLuint rotate()
{
  GLfloat vx[4] = {0};
  GLfloat vy[4] = {0};
  GLsizei w = (GLsizei)(tfParams[1]);
  GLsizei h = (GLsizei)(tfParams[2]);
  GLsizei c = (GLsizei)(tfParams[3]);
  GLsizei wo = (GLsizei)(tfParams[4]);
  GLsizei ho = (GLsizei)(tfParams[5]);
  vx[0] = tfParams[6];
  vx[1] = tfParams[7];
  vx[2] = tfParams[8];
  vx[3] = tfParams[9];
  vy[0] = tfParams[10];
  vy[1] = tfParams[11];
  vy[2] = tfParams[12];
  vy[3] = tfParams[13];
  GLfloat vertexData[] = {vx[0], vy[0], 0.0, 1.0, vx[1], vy[1], 0.0, 1.0, vx[2], vy[2], 0.0, 1.0, vx[3], vy[3], 0.0, 1.0};
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- rotate : %d, %d, %d\n", w, h, c);
  
  tfGenSurface(wo, ho);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[rotateIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, vertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, wo, ho);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- centerCrop : %d, %d, %d, %f, %f\n", w, h, c, dx, dy);
  
  tfGenSurface(wo, ho);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[centercropIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, vertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, wo, ho);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- centerCrop : %d, %d, %d, %d, %d\n", w, h, c, wo, ho);
  
  tfGenSurface(wo, ho);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[centerinsideIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, wo, ho);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- fitCenter : %d, %d, %d, %d, %d\n", w, h, c, wo, ho);
  
  tfGenSurface(wo, ho);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[fitcenterIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, wo, ho);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- circleCrop : %d, %d, %d, %f, %f\n", w, h, c, dx, dy);
  
  tfGenSurface(wo, ho);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[circlecropIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, vertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint resUni = glGetUniformLocation(prog, "resolution");
  glUniform2f(resUni, (GLfloat)w, (GLfloat)h);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, wo, ho);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, wo, ho, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- roundedcorners : %d, %d, %d, %f, %f, %f, %f\n", w, h, c, radiusTL, radiusTR, radiusBL, radiusBR);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[roundedcornersIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint resUni = glGetUniformLocation(prog, "resolution");
  glUniform2f(resUni, (GLfloat)w, (GLfloat)h);
  //1 bl, 2 br, 3 tl, 4 tr
  GLuint rblUni = glGetUniformLocation(prog, "radius1");
  glUniform1f(rblUni, radiusBL);
  GLuint rbrUni = glGetUniformLocation(prog, "radius2");
  glUniform1f(rbrUni, radiusBR);
  GLuint rtlUni = glGetUniformLocation(prog, "radius3");
  glUniform1f(rtlUni, radiusTL);
  GLuint rtrUni = glGetUniformLocation(prog, "radius4");
  glUniform1f(rtrUni, radiusTR);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
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
  printf("gl_log -cc- filter context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  printf("gl_log -cc- fastBlur : %d, %d, %d, %f\n", w, h, c, radius);
  
  tfGenSurface(w, h);
  
  GLuint texId;
  glGenTextures(1, &texId);
  if (!texId) return tfTexError;
  tfLoadTextureRGBA(texId, tfIn, w, h);

  GLuint prog = tfEnv.progIds[fastblurIdx];
  glUseProgram(prog);
  GLuint posAtb = glGetAttribLocation(prog, "a_position");
  glEnableVertexAttribArray(posAtb);
  glVertexAttribPointer(posAtb, 4, GL_FLOAT, GL_FALSE, 0, defaultVertexData);
  GLuint texCdAtb = glGetAttribLocation(prog, "a_texcoord");
  glEnableVertexAttribArray(texCdAtb);
  glVertexAttribPointer(texCdAtb, 2, GL_FLOAT, GL_FALSE, 0, defaultTexCoordData);

  GLuint radiusUni = glGetUniformLocation(prog, "r");
  glUniform1i(radiusUni, radius);

  glActiveTexture(0);
  glBindTexture(GL_TEXTURE_2D, texId);
  GLuint texUni = glGetUniformLocation(prog, "u_texture");
  glUniform1i(texUni, 0);

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, w, h);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, tfOut);

  glDisableVertexAttribArray(posAtb);
  glDisableVertexAttribArray(texCdAtb);
  glBindTexture(GL_TEXTURE_2D, GL_NONE);
  glDeleteTextures(1, &texId);

  glFinish();

  return 0;
}

unsigned int tfProc()
{
  printf("gl_log -cc- tfProc context : %lu, %lu, %lu, %lu\n", (GLuint64)eglGetCurrentDisplay(), (GLuint64)eglGetCurrentSurface(EGL_DRAW), (GLuint64)eglGetCurrentSurface(EGL_READ), (GLuint64)eglGetCurrentContext());
  int type = (int)(tfParams[0]);
  switch (type)
  { 
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

///////////////////////////////////////////////////////////////

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
  if(ret) {
    printf("gl_log c error: pthread_detach fail : %d\n", ret);
  }
  

  pthread_mutex_lock(&mutexGlEnv);
  tfInit();
  pthread_mutex_unlock(&mutexGlEnv);

  while(tFlg) {
    printf("gl_log thread ready : %lu\n", getThreadId());
    pthread_mutex_lock(&mutex);
    ready = 0;
    while (!ready) {
        pthread_cond_wait(&cond, &mutex);
    }
    pthread_mutex_unlock(&mutex);

    //pthread_mutex_lock(&mutexGlEnv);
    //filter
    tfProc();
    //pthread_mutex_unlock(&mutexGlEnv);

   
    pthread_mutex_lock(&mutex2);
    ready2 = 1;
    pthread_cond_broadcast(&cond2);
    pthread_mutex_unlock(&mutex2);
    // sleep(2);
  }

  //pthread_mutex_lock(&mutexGlEnv);
  tfRelease();
  //pthread_mutex_unlock(&mutexGlEnv);

  pthread_exit(NULL);
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
  
  pthread_create(&th1,NULL,thread_func,NULL);
  return th1;
}

void stopThread()
{
  tFlg = false;
  if(!ready) {
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

unsigned int setTask(unsigned int a)
{

  pthread_mutex_lock(&mutexGlEnv);
  param = a;
  pthread_mutex_unlock(&mutexGlEnv);

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

  return res;
}

unsigned int tfTask(unsigned char* pOut,
                    unsigned char* pIn, 
                    float* pparam)
{

  pthread_mutex_lock(&mutexGlEnv);
  memcpy(tfParams, pparam, sizeof(float) * GLENV_PARAM_MAX_NUM);
  tfIn = pIn;
  tfOut = pOut;

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
  pthread_mutex_unlock(&mutexGlEnv);

  return tfRet;
}

