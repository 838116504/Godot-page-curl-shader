shader_type canvas_item;

uniform vec2 curlPosA;
uniform vec2 curlPosB;
uniform float curlRadius = 0.01f;
uniform float curlAngle:hint_range(-180f, 180f) = 0f;			// 正代表往左翻, 單位角度
uniform vec2 pageSize;

uniform sampler2D back;

vec2 get_curl_normal()
{
	vec2 v = curlPosB - curlPosA;
	vec2 n = normalize(vec2(-v.y, v.x));
	if (n.x > 0f)
		n = -n;
	return n * sign(curlAngle);
}

vec2 get_curl_intersect_point(vec2 p_uv)
{
	vec2 uv = p_uv;
	float a = curlPosB.y - curlPosA.y, b = curlPosA.x - curlPosB.x, c = curlPosB.x * curlPosA.y - curlPosA.x * curlPosB.y;
	vec2 dir = curlPosB - curlPosA;
	vec2 uv2 = uv + vec2(-dir.y, dir.x);
	float a2 = uv2.y - uv.y, b2 = uv.x - uv2.x, c2 = uv2.x * uv.y - uv.x * uv2.y;
	float m = a * b2 - a2 * b;
	if (m == 0f)
		return vec2(0f);
	
	return vec2((c2 * b - c * b2) / m, (c * a2 - c2 * a) / m);
}

vec4 get_offset_and_scale()
{
	float deg = abs(curlAngle);
	if (deg <= 90f)
	{
		return vec4(0f, 0f, 1f, 1f);
	}
	
	vec2 corners[4];
	corners[0] = vec2(0f);
	corners[1] = vec2(pageSize.x, 0f);
	corners[2] = vec2(pageSize);
	corners[3] = vec2(0f, pageSize.y);
	
	vec2 n = -get_curl_normal();
	vec2 leftTopExpand = vec2(0f);
	vec2 rightBottomExpand = vec2(0f);
	
	float rad = radians(deg);
	float arcLen = rad * curlRadius;
	float d1 = sin(radians(180f - deg)) * curlRadius;
	for (int i = 0; i < 4; ++i)
	{
		vec2 intersect = get_curl_intersect_point(corners[i]);
		if (dot(n, corners[i] - intersect) <= 0f)
			continue;
		
		float dist = distance(intersect, corners[i]);
		
		
		vec2 pos = vec2(0f);
		if (dist < arcLen)
		{
			float a = dist / curlRadius;
			pos = n * (sin(radians(180f) - a) * curlRadius) + intersect;
		} else
		{
			float d = d1 - cos(radians(180f - deg)) * (dist - arcLen);
			pos = n * d + intersect;
		}
		
		leftTopExpand.x = max(leftTopExpand.x, -pos.x);
		rightBottomExpand.x = max(rightBottomExpand.x, pos.x - pageSize.x);
		leftTopExpand.y = max(leftTopExpand.y, -pos.y);
		rightBottomExpand.y = max(rightBottomExpand.y, pos.y - pageSize.y);
	}
	
	
	return vec4(-leftTopExpand / pageSize, vec2(1f) + (leftTopExpand + rightBottomExpand) / pageSize);
}

void vertex()
{
	vec4 offsetScale = get_offset_and_scale();
	vec2 offset = offsetScale.xy * pageSize;
	VERTEX = VERTEX * offsetScale.zw + offset;
	UV = UV * offsetScale.zw + offsetScale.xy;
}

void fragment()
{
	float deg = abs(curlAngle);
	if (deg < 0.001)
	{
		COLOR = texture(TEXTURE, UV);
	} else
	{
		vec2 n = get_curl_normal();
		vec2 uv = UV * pageSize;
		vec2 intersect = get_curl_intersect_point(uv);
		float dist = distance(intersect, uv) * sign(dot(n, uv - intersect));
		vec2 uvTop = vec2(-1f);
		vec2 uvBottom = vec2(-1f);
		float rad = radians(deg);
		if (dist + curlRadius < 0f)
		{
			if (deg < 90f)
			{
				float d1 = curlRadius * sin(rad);
				float d2 = -dist - d1;
				float len = rad * curlRadius + d2 / cos(rad);
				uvTop = -n * len + intersect;
			}
		} else if (dist < 0f)
		{
			float a = asin(-dist/curlRadius);
			float aTop = radians(180f) - a;
			uvBottom = -n * (a * curlRadius) + intersect;
			if (aTop <= rad)
			{
				uvTop = -n * aTop * curlRadius + intersect;
				
			} else 
			{
				if (deg == 90f)
				{
				}
				else if (deg < 90f)
				{
					float d1 = curlRadius * sin(rad);
					float d2 = -dist - d1;
					float len = rad * curlRadius + d2 / cos(rad);
					uvBottom = -n * (rad * curlRadius + len) + intersect;
				} else
				{
					float d1 = cos(radians(deg - 90f)) * curlRadius;
					float d2 = d1 + dist;
					float len = rad * curlRadius + d2 / cos(radians(180f - deg));
					uvTop = -n * len + intersect;
				}
			}
			
		} else
		{
			uvBottom = uv;
			if (deg >= 180f)
			{
				uvTop = -n * (radians(180f) * curlRadius + dist) + intersect;
			} else if (deg > 90f)
			{
				float d1 = cos(radians(deg - 90f)) * curlRadius;
				float d2 = d1 + dist;
				float len = rad * curlRadius + d2 / cos(radians(180f - deg));
				uvTop = -n * len + intersect;
			}
		}
		
		
		if (uvTop.x >= 0f && uvTop.x <= pageSize.x && uvTop.y >= 0f && uvTop.y <= pageSize.y)
		{
			COLOR = texture(back, vec2(1.0 - uvTop.x / pageSize.x, uvTop.y / pageSize.y));
		} else if (uvBottom.x >= 0f && uvBottom.x <= pageSize.x && uvBottom.y >= 0f && uvBottom.y <= pageSize.y)
		{
			COLOR = texture(TEXTURE, vec2(uvBottom.x / pageSize.x, uvBottom.y / pageSize.y));
		} else
		{
			discard;
		}
		
	}
}
