precision mediump float;

const float PI = 3.14159265;
uniform sampler2D Texture;

const float uD = 80.0;
const float uR = 0.5;

varying vec2 TextureCoordsVarying;

void main()
{
    ivec2 ires = ivec2(512, 512);
    float Res = float(ires.y);
    
    vec2 st = TextureCoordsVarying;
    float Radius = Res * uR;
    
    vec2 xy = Res * st;
    
    vec2 dxy = xy - vec2(Res/2., Res/2.);
    float r = length(dxy);
    
    float attenValue = (1.0 -(r/Radius)*(r/Radius));
    float beta = atan(dxy.y, dxy.x) + radians(uD) * 2.0 * attenValue;
  
    if(r <= Radius)
    {
        xy = Res/2.0 + r * vec2(cos(beta), sin(beta));
    }
    
    st = xy/Res;
    
    vec3 irgb = texture2D(Texture, st).rgb;
    
    gl_FragColor = vec4( irgb, 1.0 );
}
