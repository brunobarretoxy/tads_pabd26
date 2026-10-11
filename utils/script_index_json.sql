DROP TABLE IF EXISTS employee_json;

CREATE TABLE employee_json (
    id   SERIAL PRIMARY KEY,
    data JSONB NOT NULL
);

INSERT INTO employee_json (data) VALUES
('{
    "first_name": "Gael",
    "last_name": "Santos",
    "position": "Developer",
    "salary": 25789,
    "active": true,
    "skills": ["sql", "javascript", "react"],
    "address": {
        "city": "Teresina",
        "state": "PI",
        "country": "Brasil"
    }
}'),
('{
    "first_name": "João",
    "last_name": "Silva",
    "position": "Developer",
    "salary": 5200,
    "active": true,
    "skills": ["sql", "python", "docker"],
    "address": {
        "city": "Natal",
        "state": "RN",
        "country": "Brasil"
    }
}'),
('{
    "first_name": "Maria",
    "last_name": "Souza",
    "position": "Analyst",
    "salary": 4300,
    "active": true,
    "skills": ["sql", "react"],
    "address": {
        "city": "Recife",
        "state": "PE",
        "country": "Brasil"
    }
}'),
('{
    "first_name": "John",
    "last_name": "Doe",
    "position": "Manager",
    "salary": 7800,
    "active": false,
    "skills": ["vue", "sql"],
    "address": {
        "city": "Carteret",
        "state": "NJ",
        "country": "EUA"
    }
}'),
('{
    "first_name": "Ana",
    "last_name": "Pereira",
    "position": "Developer",
    "salary": 5900,
    "active": true,
    "skills": ["python", "docker", "kubernetes"],
    "address": {
        "city": "New York",
        "state": "NY",
        "country": "EUA"
    }
}');

INSERT INTO employee_json (data) VALUES
('{
    "first_name": "George",
    "last_name": "Santos",
    "position": "Developer",
    "salary": 25789,
    "skills": ["sql", "javascript", "react"],
    "address": {
        "city": "Teresina",
        "state": "PI",
        "country": "Brasil"
    }
}');