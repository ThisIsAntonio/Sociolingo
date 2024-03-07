import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDataLoader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, List<String>>> topicsAndHobbiesByLanguage = {
    "en": {
      "Science": [
        "Astronomy",
        "Biology",
        "Chemistry",
        "Physics",
        "Environmental Science"
      ],
      "Technology": [
        "Programming",
        "Cybersecurity",
        "Gaming",
        "Gadgetry",
        "Web Development"
      ],
      "Mathematics": [
        "Algebra",
        "Calculus",
        "Geometry",
        "Statistics",
        "Trigonometry"
      ],
      "History": [
        "Ancient Civilizations",
        "Modern History",
        "Medieval Europe",
        "World Wars",
        "American History"
      ],
      "Art": [
        "Painting",
        "Sculpture",
        "Photography",
        "Digital Art",
        "Printmaking"
      ],
      "Music": ["Classical", "Jazz", "Rock", "Electronic", "World Music"],
      "Literature": ["Novels", "Poetry", "Drama", "Fantasy", "Mystery"],
      "Physics": [
        "Quantum Mechanics",
        "Thermodynamics",
        "Electromagnetism",
        "Classical Mechanics",
        "Astrophysics"
      ],
      "Chemistry": [
        "Organic Chemistry",
        "Inorganic Chemistry",
        "Analytical Chemistry",
        "Physical Chemistry",
        "Biochemistry"
      ],
      "Biology": [
        "Molecular Biology",
        "Ecology",
        "Genetics",
        "Evolutionary Biology",
        "Microbiology"
      ],
      "Geography": [
        "Physical Geography",
        "Human Geography",
        "Geospatial Technology",
        "Environmental Geography",
        "Cultural Geography"
      ],
      "Philosophy": [
        "Ethics",
        "Logic",
        "Metaphysics",
        "Aesthetics",
        "Epistemology"
      ],
      "Psychology": [
        "Clinical Psychology",
        "Cognitive Psychology",
        "Developmental Psychology",
        "Social Psychology",
        "Behavioral Psychology"
      ],
      "Medicine": [
        "General Practice",
        "Surgery",
        "Psychiatry",
        "Dermatology",
        "Pediatrics"
      ],
      "Economics": [
        "Microeconomics",
        "Macroeconomics",
        "International Economics",
        "Developmental Economics",
        "Behavioral Economics"
      ],
      "Astronomy": [
        "Stellar Astrophysics",
        "Galactic Astronomy",
        "Cosmology",
        "Planetary Science",
        "Observational Astronomy"
      ],
      "Engineering": [
        "Mechanical Engineering",
        "Electrical Engineering",
        "Civil Engineering",
        "Chemical Engineering",
        "Software Engineering"
      ],
      "Environment": [
        "Conservation",
        "Sustainability",
        "Climate Change",
        "Renewable Energy",
        "Environmental Policy"
      ],
      "Sociology": [
        "Social Theory",
        "Urban Sociology",
        "Criminology",
        "Cultural Sociology",
        "Political Sociology"
      ],
      "Politics": [
        "Political Theory",
        "International Relations",
        "Comparative Politics",
        "Public Policy",
        "Political Economy"
      ],
    },
    "es": {
      "Ciencia": [
        "Astronomía",
        "Biología",
        "Química",
        "Física",
        "Ciencia medioambiental"
      ],
      "Tecnología": [
        "Programación",
        "La seguridad cibernética",
        "Juego de azar",
        "Aparatos",
        "Desarrollo web"
      ],
      "Matemáticas": [
        "Álgebra",
        "Cálculo",
        "Geometría",
        "Estadísticas",
        "Trigonometría"
      ],
      "Historia": [
        "Civilizaciones antiguas",
        "Historia moderna",
        "Europa medieval",
        "Guerras mundiales",
        "Historia americana"
      ],
      "Arte": ["Cuadro", "Escultura", "Fotografía", "Arte digital", "Grabado"],
      "Música": ["Clásica", "Jazz", "Rock", "Electrónica", "Música del mundo"],
      "Literatura": ["Novelas", "Poesía", "Drama", "Fantasía", "Misterio"],
      "Física": [
        "Mecánica cuántica",
        "Termodinámica",
        "Electromagnetismo",
        "Mecanica clasica",
        "Astrofísica"
      ],
      "Química": [
        "Química Orgánica",
        "Química Inorgánica",
        "Química analítica",
        "Química Física",
        "Bioquímica"
      ],
      "Biología": [
        "Biología Molecular",
        "Ecología",
        "Genética",
        "Biología evolucionaria",
        "Microbiología"
      ],
      "Geografía": [
        "Geografía Física",
        "Geografía Humana",
        "Tecnología Geoespacial",
        "Geografía Ambiental",
        "Geografía cultural"
      ],
      "Filosofía": [
        "Ética",
        "Lógica",
        "Metafísica",
        "Estética",
        "Epistemología"
      ],
      "Psicología": [
        "Psicología clínica",
        "Psicología cognitiva",
        "Psicología del desarrollo",
        "Psicología Social",
        "Psicología del comportamiento"
      ],
      "Medicamento": [
        "Práctica general",
        "Cirugía",
        "Psiquiatría",
        "Dermatología",
        "Pediatría"
      ],
      "Economía": [
        "Microeconomía",
        "Macroeconómica",
        "Economía Internacional",
        "Economía del desarrollo",
        "Conducta economica"
      ],
      "Astronomía": [
        "Astrofísica Estelar",
        "Astronomía Galáctica",
        "Cosmología",
        "Ciencia Planetaria",
        "Astronomía observacional"
      ],
      "Ingeniería": [
        "Ingeniería Mecánica",
        "Ingenieria Eléctrica",
        "Ingeniería civil",
        "Ingeniería Química",
        "Ingeniería de software"
      ],
      "Ambiente": [
        "Conservación",
        "Sostenibilidad",
        "Cambio climático",
        "Energía renovable",
        "Política de medio ambiente"
      ],
      "Sociología": [
        "Teoría Social",
        "Sociología Urbana",
        "Criminología",
        "Sociología Cultural",
        "Sociología política"
      ],
      "Política": [
        "Teoría política",
        "Relaciones Internacionales",
        "Politica comparativa",
        "Política pública",
        "Economía política"
      ],
    },
    "fr": {
      "Science": [
        "Astronomie",
        "La biologie",
        "Chimie",
        "La physique",
        "Sciences de l'environnement"
      ],
      "Technologie": [
        "La programmation",
        "La cyber-sécurité",
        "Jeux",
        "Gadget",
        "Développement web"
      ],
      "Mathématiques": [
        "Algèbre",
        "Calcul",
        "Géométrie",
        "Statistiques",
        "Trigonométrie"
      ],
      "Histoire": [
        "Civilisations anciennes",
        "Histoire moderne",
        "L'Europe médiévale",
        "Guerres mondiales",
        "Histoire américaine"
      ],
      "Art": [
        "Peinture",
        "Sculpture",
        "La photographie",
        "Art numérique",
        "La gravure"
      ],
      "Musique": ["Classique", "Jazz", "Rock", "Électronique", "World Music"],
      "Littérature": ["Romans", "Poésie", "Drame", "Fantastique", "Mystère"],
      "La physique": [
        "Mécanique quantique",
        "Thermodynamique",
        "Electromagnétisme",
        "Mécanique classique",
        "Astrophysique"
      ],
      "Chimie": [
        "Chimie organique",
        "Chimie inorganique",
        "Chimie analytique",
        "Chimie physique",
        "Biochimie"
      ],
      "La biologie": [
        "Biologie moléculaire",
        "Écologie",
        "La génétique",
        "Biologie de l'évolution",
        "Microbiologie"
      ],
      "Géographie": [
        "Géographie physique",
        "Géographie humaine",
        "Technologie géospatiale",
        "Géographie environnementale",
        "Géographie culturelle"
      ],
      "Philosophie": [
        "Éthique",
        "Logique",
        "Métaphysique",
        "Esthétique",
        "Épistémologie"
      ],
      "Psychologie": [
        "Psychologie clinique",
        "Psychologie cognitive",
        "La psychologie du développement",
        "La psychologie sociale",
        "Psychologie comportementale"
      ],
      "Médecine": [
        "Pratique générale",
        "Chirurgie",
        "Psychiatrie",
        "Dermatologie",
        "Pédiatrie"
      ],
      "Économie": [
        "Microéconomie",
        "Macroéconomie",
        "L'économie internationale",
        "Économie du développement",
        "Économie comportementale"
      ],
      "Astronomie": [
        "Astrophysique Stellaire",
        "Astronomie Galactique",
        "Cosmologie",
        "Science planétaire",
        "Astronomie d'observation"
      ],
      "Ingénierie": [
        "Génie mécanique",
        "Ingénierie électrique",
        "Génie civil",
        "Ingénieur chimiste",
        "Génie logiciel"
      ],
      "Environnement": [
        "Conservation",
        "Durabilité",
        "Changement climatique",
        "Énergie renouvelable",
        "Politique environnementale"
      ],
      "Sociologie": [
        "Théorie sociale",
        "Sociologie urbaine",
        "Criminologie",
        "Sociologie culturelle",
        "Sociologie politique"
      ],
      "Politique": [
        "Théorie politique",
        "Relations internationales",
        "Politiques comparées",
        "Politique publique",
        "Économie politique"
      ],
    },
  };

  Future<void> uploadTopicsAndHobbies() async {
    topicsAndHobbiesByLanguage.forEach((language, topicsAndHobbies) async {
      int topicCounter = 1; // Inicia un contador para los temas

      for (var topicName in topicsAndHobbies.keys) {
        String topicId =
            'topic_${topicCounter.toString().padLeft(3, '0')}'; // Crea un ID basado en el contador
        var topicDocRef =
            _firestore.collection('topics_$language').doc(topicId);

        await topicDocRef.set({
          'id': topicId,
          'name': topicName,
        });

        int hobbyCounter =
            1; // Inicia un contador para los hobbies dentro de cada tema

        for (var hobby in topicsAndHobbies[topicName]!) {
          String hobbyId =
              'hobby_${topicCounter.toString().padLeft(3, '0')}_${hobbyCounter.toString().padLeft(3, '0')}'; // Crea un ID combinando los contadores de tema y hobby

          await topicDocRef.collection('hobbies').doc(hobbyId).set({
            'id': hobbyId,
            'name': hobby,
          });

          hobbyCounter++; // Incrementa el contador de hobbies para el siguiente hobby
        }

        topicCounter++; // Incrementa el contador de temas para el siguiente tema
      }
    });
  }
}
