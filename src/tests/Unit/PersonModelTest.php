<?php

namespace Tests\Unit;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Tests\TestCase;
use App\Person;
use App\Contact;

class PersonModelTest extends TestCase
{
    /**
     * Test if Person model contains constants for defining person types
     */
    public function testItContainsConstantsForTypes()
    {
        $this->assertEquals(0, Person::TYPE_PERSON);
        $this->assertEquals(1, Person::TYPE_COMPANY);
        $this->assertEquals(
            [
                Person::TYPE_PERSON,
                Person::TYPE_COMPANY,
            ],
            Person::AVAILABLE_TYPES
        );
    }

    /**
     * Test if Person model contains constants for defining person gender
     */
    public function testItContainsConstantsForGenders()
    {
        $this->assertEquals(0, Person::GENDER_MALE);
        $this->assertEquals(1, Person::GENDER_FEMALE);
        $this->assertEquals(
            [
                Person::GENDER_MALE,
                Person::GENDER_FEMALE,
            ],
            Person::AVAILABLE_GENDERS
        );
    }

    /**
     * Test if Person model contains a HasMany relationship to Contact model
     */
    public function testItHaveContactsRelationship()
    {
        $person = new Person();

        $this->assertInstanceOf(HasMany::class, $person->contacts());
        $this->assertInstanceOf(Contact::class, $person->contacts()->getQuery()->getModel());
    }
}
