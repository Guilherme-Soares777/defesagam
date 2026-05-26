import processing.sound.*; 

// Imagens e Sons
PImage bgImg, baseImg, canoImg, heliImg, pqdImg, projetilImg;
SoundFile somExplosao; 

// Listas para os tiros e inimigos no ecrã
ArrayList<Bullet> bullets;
ArrayList<Helicopter> helicopters;
ArrayList<Paratrooper> pqds;
ArrayList<Particle> particles;

// O jogador (canhão)
Player player;

// Variáveis do jogo
int score = 0;
int vidas = 3; 
int heliSpawnTimer = 0;
int gameState = 0; // 0: Loading, 1: A jogar, 2: Game Over
int loadStartTime;
int lastMissileTime = -3000; // Tempo do míssil

void setup() {
  size(800, 600); // Tamanho da janela
  imageMode(CENTER); 
  
  // Prepara as listas
  bullets = new ArrayList<Bullet>();
  helicopters = new ArrayList<Helicopter>();
  pqds = new ArrayList<Paratrooper>();
  particles = new ArrayList<Particle>();
  
  // Carrega as imagens
  bgImg = loadImage("fundo.jpg");
  if (bgImg != null) bgImg.resize(width, height);
  
  baseImg = loadImage("base.png");
  if (baseImg != null) baseImg.resize(80, 80);
  
  canoImg = loadImage("cano.png");
  if (canoImg != null) canoImg.resize(80, 80);
  
  heliImg = loadImage("heli.png");
  if (heliImg != null) heliImg.resize(140, 60);
  
  pqdImg = loadImage("paraquedista.png");
  if (pqdImg != null) pqdImg.resize(45, 65);
  
  projetilImg = loadImage("tiro.png"); 
  if (projetilImg != null) projetilImg.resize(15, 35); 
  
  // Carrega o som
  try {
    somExplosao = new SoundFile(this, "explosion.mp3");
  } catch (Exception e) {
    println("Erro no som da explosão.");
  }
  
  player = new Player();
  loadStartTime = millis(); 
}

void draw() {
  // --- TELA DE LOADING ---
  if (gameState == 0) {
    background(0);
    fill(255);
    textSize(28);
    textAlign(CENTER, CENTER);
    text("A esconder os bugs do professor... Aguarda.", width/2, height/2);
    
    // Inicia o jogo após 2.5 segundos
    if (millis() - loadStartTime > 2500) {
      gameState = 1;
    }
    return; 
  }
  
  // --- TELA DE GAME OVER ---
  if (gameState == 2) {
    background(50, 0, 0); 
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(50);
    text("GAME OVER", width/2, height/2 - 40);
    textSize(24);
    text("Pontuação Final: " + score, width/2, height/2 + 20);
    textSize(18);
    text("Clica no ecrã para tentar novamente", width/2, height/2 + 70);
    return; 
  }
  
  // --- JOGO A CORRER ---
  
  // Desenha o fundo
  if (bgImg != null) {
    imageMode(CORNER);
    image(bgImg, 0, 0);
    imageMode(CENTER);
  } else {
    background(50);
  }
  
  // Dificuldade: helicópteros aparecem mais rápido com o tempo
  int currentSpawnRate = (int) max(40, 120 - (score / 10));
  
  heliSpawnTimer++;
  if (heliSpawnTimer > currentSpawnRate) { 
    helicopters.add(new Helicopter()); 
    heliSpawnTimer = 0;
  }
  
  // Atualiza tiros
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();
    if (b.x < 0 || b.x > width || b.y < 0) bullets.remove(i);
  }
  
  // Atualiza helicópteros
  for (int i = helicopters.size() - 1; i >= 0; i--) {
    Helicopter h = helicopters.get(i);
    h.update();
    h.display();
    if (h.x < -200 || h.x > width + 200) helicopters.remove(i);
  }
  
  // Atualiza paraquedistas
  for (int i = pqds.size() - 1; i >= 0; i--) {
    Paratrooper p = pqds.get(i);
    p.update();
    p.display();
    
    // Se o paraquedista chegar ao chão, perde vida
    if (p.y > height) {
      pqds.remove(i); 
      vidas--; 
      if (vidas <= 0) {
        gameState = 2; // Fim de jogo
      }
    }
  }
  
  // Atualiza faíscas
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle part = particles.get(i);
    part.update();
    part.display();
    if (part.timer <= 0) particles.remove(i); 
  }
  
  // --- COLISÕES ---
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    boolean hit = false;
    
    // Tiro no Helicóptero
    for (int j = helicopters.size() - 1; j >= 0; j--) {
      Helicopter h = helicopters.get(j);
      
      if (dist(b.x, b.y, h.x, h.y) < 50) { 
        
        // Dano: Míssil tira 3, Tiro normal tira 1
        if (b.isMissile) h.hp -= 3; 
        else { h.hp -= 1; h.hitTimer = 5; }
        
        // Se morreu
        if (h.hp <= 0) {
          if (somExplosao != null) somExplosao.play(); 
          
          // Cria faíscas
          for (int k = 0; k < 20; k++) {
            particles.add(new Particle(h.x, h.y, color(255, random(100, 200), 0))); 
          }
          
          helicopters.remove(j); 
          score += 50; 
        }
        
        hit = true;
        break; 
      }
    }
    
    if (hit) {
      bullets.remove(i);
      continue; 
    }
    
    // Tiro no Paraquedista
    for (int j = pqds.size() - 1; j >= 0; j--) {
      Paratrooper p = pqds.get(j);
      if (dist(b.x, b.y, p.x, p.y) < 25) { 
        
        // Cria faíscas vermelhas
        for (int k = 0; k < 15; k++) {
          particles.add(new Particle(p.x, p.y, color(139, 0, 0)));
        }
        
        pqds.remove(j); 
        hit = true;
        score += 10; 
        break; 
      }
    }
    
    if (hit) bullets.remove(i);
  }
  
  // Desenha o canhão
  player.display();
  
  // --- TEXTOS NO ECRÃ ---
  fill(255);
  textSize(24);
  textAlign(LEFT, TOP);
  text("Pontos: " + score, 10, 10);
  
  textAlign(RIGHT, TOP);
  fill(vidas == 1 ? color(255, 0, 0) : color(255)); // Vermelho se tiver 1 vida
  text("Vidas: " + vidas, width - 10, 10);
  
  // Status do Míssil
  textAlign(RIGHT, BOTTOM);
  int timeSinceMissile = millis() - lastMissileTime;
  if (timeSinceMissile >= 3000) {
    fill(0, 255, 0); 
    text("Míssil (Botão Direito): PRONTO", width - 10, height - 10);
  } else {
    fill(255, 0, 0); 
    float faltam = 3.0 - (timeSinceMissile / 1000.0);
    text("Míssil (Botão Direito): " + nf(faltam, 1, 1) + "s", width - 10, height - 10);
  }
}

// --- CLIQUE DO RATO ---
void mousePressed() {
  if (gameState == 1) {
    // Calcula a mira
    float angle = atan2(mouseY - player.y, mouseX - player.x);
    float pontaCanhaoX = player.x + cos(angle) * 40;
    float pontaCanhaoY = player.y + sin(angle) * 40;
    
    if (mouseButton == LEFT) {
      bullets.add(new Bullet(pontaCanhaoX, pontaCanhaoY, mouseX, mouseY, false)); // Tiro normal
    } else if (mouseButton == RIGHT) {
      if (millis() - lastMissileTime >= 3000) { 
        bullets.add(new Bullet(pontaCanhaoX, pontaCanhaoY, mouseX, mouseY, true)); // Míssil
        lastMissileTime = millis(); 
      }
    }
  } 
  // Reinicia o jogo no Game Over
  else if (gameState == 2) {
    score = 0;
    vidas = 3;
    lastMissileTime = millis() - 3000;
    bullets.clear();
    helicopters.clear();
    pqds.clear();
    particles.clear();
    gameState = 1;
  }
}

// ================= CLASSES =================

// Canhão e Base
class Player {
  float x, y;
  Player() {
    x = width / 2;
    y = height - 40; 
  }
  void display() {
    // Desenha a base parada
    if (baseImg != null) image(baseImg, x, y + 15); 
    
    // Roda apenas o cano para seguir o rato
    float angle = atan2(mouseY - y, mouseX - x); 
    pushMatrix();
    translate(x, y - 5); 
    rotate(angle);
    if (canoImg != null) image(canoImg, 25, 0); 
    popMatrix();
  }
}

// Tiros
class Bullet {
  float x, y, dx, dy;
  float speed = 15;
  float renderAngle; 
  boolean isMissile; 
  
  Bullet(float startX, float startY, float targetX, float targetY, boolean isMissileInput) {
    x = startX;
    y = startY;
    isMissile = isMissileInput;
    
    float angle = atan2(targetY - startY, targetX - startX);
    speed = isMissile ? 12 : 20; 
    dx = cos(angle) * speed;
    dy = sin(angle) * speed;
    renderAngle = angle + HALF_PI; 
  }
  void update() { x += dx; y += dy; }
  void display() {
    if (isMissile && projetilImg != null) {
      pushMatrix();
      translate(x, y);
      rotate(renderAngle); 
      image(projetilImg, 0, 0);
      popMatrix();
    } else {
      fill(255, 255, 0);
      noStroke();
      ellipse(x, y, 8, 8);
    }
  }
}

// Helicópteros
class Helicopter {
  float x, y, speed;
  int direction;
  int spawnTimer = 0;
  int hp = 3; 
  int hitTimer = 0; 
  
  Helicopter() {
    y = random(30, 150);
    speed = random(3, 5);
    direction = random(1) > 0.5 ? 1 : -1; 
    if (direction == 1) x = -100; else { x = width + 100; speed *= -1; }
  }
  void update() {
    x += speed;
    spawnTimer++;
    
    // Larga um paraquedista aleatoriamente
    if (spawnTimer > 60 && random(1) < 0.02 && x > 50 && x < width - 50) {
      pqds.add(new Paratrooper(x, y + 30)); 
      spawnTimer = 0;
    }
    if (hitTimer > 0) hitTimer--;
  }
  void display() {
    if (heliImg != null) {
      pushMatrix();
      translate(x, y);
      if (direction == 1) scale(-1, 1); 
      if (hitTimer > 0) tint(255, 100, 100); // Pisca vermelho se levar dano
      image(heliImg, 0, 0);
      noTint(); 
      popMatrix();
    }
  }
}

// Paraquedistas
class Paratrooper {
  float x, y, speedY;
  Paratrooper(float startX, float startY) {
    x = startX; y = startY;
    speedY = random(1.5, 2.5);
  }
  void update() { y += speedY; }
  void display() { if (pqdImg != null) image(pqdImg, x, y); }
}

// Faíscas
class Particle {
  float x, y, vx, vy, timer, size;
  color c;
  Particle(float startX, float startY, color particleColor) {
    x = startX; y = startY;
    vx = random(-4, 4); 
    vy = random(-5, 1); 
    timer = random(20, 40); 
    size = random(3, 6);
    c = particleColor; 
  }
  void update() {
    x += vx; y += vy;
    vy += 0.3; // Gravidade
    timer--;
  }
  void display() {
    fill(c); noStroke();
    rectMode(CENTER);
    rect(x, y, size, size);
    rectMode(CORNER);
  }
}
